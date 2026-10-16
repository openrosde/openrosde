// This script checks GLB files with the Khronos glTF-Validator, and fails on any error or warning, on a header other than glTF 2.0 binary, or on any required extension, as the robot model contract of 'docs/robot-models.md' demands.
// It needs the npm package 'gltf-validator', which 'gitlab-ci/check-mesh-glbs.bash' installs at a pinned version.
//
// Usage: node ./gitlab-ci/validate-glbs.mjs <file.glb> [<file.glb> ...]

import fs from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(process.cwd() + "/");
const validator = require("gltf-validator");

let failures = 0;
for (const path of process.argv.slice(2)) {
  const data = new Uint8Array(fs.readFileSync(path));
  const header = new DataView(data.buffer, data.byteOffset, 12);
  const problems = [];
  if (header.getUint32(0, true) !== 0x46546c67 || header.getUint32(4, true) !== 2) {
    problems.push("not a glTF 2.0 binary");
  }
  try {
    const report = await validator.validateBytes(data, {
      uri: path,
      externalResourceFunction: (uri) => Promise.reject(new Error(`external resource ${uri}`)),
    });
    if (report.issues.numErrors > 0 || report.issues.numWarnings > 0) {
      const codes = [...new Set(report.issues.messages.filter((m) => m.severity <= 1).map((m) => m.code))];
      problems.push(`${report.issues.numErrors} errors and ${report.issues.numWarnings} warnings (${codes.join(", ")})`);
    }
    if ((report.info?.extensionsRequired ?? []).length > 0) {
      problems.push(`required extensions ${report.info.extensionsRequired.join(", ")}`);
    }
  } catch (error) {
    problems.push(`validation failed: ${error}`);
  }
  if (problems.length > 0) {
    failures += 1;
    console.log(`${path}: ${problems.join(", ")}`);
  }
}
console.log(`Checked ${process.argv.length - 2} GLB files, ${failures} failed.`);
process.exit(failures > 0 ? 1 : 0);
