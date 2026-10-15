#!/usr/bin/env python3
"""Convert every COLLADA, STL, and OBJ mesh of the ROS packages under the given roots into a GLB, with 'mesh2glb.py'.

A package is any folder with a 'package.xml', and a mesh belongs to the nearest package above it.
The GLB of a mesh is named by appending '.glb' to its full file name in its original case, such as 'base.dae.glb', and sits beside the mesh, or under '--out' at the same path relative to its root.
A GLB is regenerated only when it is missing, older than its mesh, or written by another generator, so that a rerun converts only what changed.
The folders 'build', 'devel', 'install', 'logs', and '.git' are skipped.
One line per mesh is printed, tab-separated: package, path in the package, seconds, bytes in, bytes out, and the status, 'ok', 'current', or the error.
A mesh that fails is skipped, so that a client falls back to the original or to the collision mesh, unless '--strict' makes the script fail.

Usage: generate-mesh-glbs.py [--out <dir>] [--strict] [--jobs <count>] <root> [<root> ...]
"""
import argparse
import concurrent.futures
import json
import os
import struct
import sys
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mesh2glb  # noqa: E402

MESH_EXTENSIONS = (".dae", ".stl", ".obj")
SKIPPED_FOLDERS = {"build", "devel", "install", "logs", ".git"}


def read_package(path):
    # Return the name and the licenses of a 'package.xml'.
    root = ET.parse(path).getroot()
    name = (root.findtext("name") or "").strip()
    licenses = [(el.text or "").strip() for el in root.findall("license") if (el.text or "").strip()]
    return name, ", ".join(licenses)


def read_generator(path):
    # Return the 'asset.generator' of a GLB, or None when it cannot be read.
    try:
        with open(path, "rb") as f:
            magic, version, _ = struct.unpack("<4sII", f.read(12))
            length, kind = struct.unpack("<I4s", f.read(8))
            if magic != b"glTF" or version != 2 or kind != b"JSON":
                return None
            return json.loads(f.read(length)).get("asset", {}).get("generator")
    except (OSError, ValueError, struct.error):
        return None


def find_meshes(root):
    # Yield every mesh under a root with the folder, the name, and the licenses of its package.
    packages = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIPPED_FOLDERS)
        parent = os.path.dirname(dirpath)
        package = packages.get(parent)
        if "package.xml" in filenames:
            try:
                package = (dirpath,) + read_package(os.path.join(dirpath, "package.xml"))
            except ET.ParseError:
                package = None
        packages[dirpath] = package
        if package is None:
            continue
        for filename in sorted(filenames):
            if os.path.splitext(filename)[1].lower() in MESH_EXTENSIONS:
                yield os.path.join(dirpath, filename), package


def generate(src, dst, package_name, rel, license_text):
    # Convert one mesh unless its GLB is current, and return its line of the report.
    started = time.time()
    if os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src) and read_generator(dst) == mesh2glb.GENERATOR:
        status = "current"
    else:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        try:
            mesh2glb.convert(src, dst, package_name, f"package://{package_name}/{rel}", license_text)
            status = "ok"
        except Exception as error:  # noqa: BLE001
            status = f"ERROR {type(error).__name__}: {error}".replace("\t", " ").replace("\n", " ")
    size = os.path.getsize(dst) if os.path.exists(dst) and not status.startswith("ERROR") else 0
    return f"{package_name}\t{rel}\t{time.time() - started:.2f}\t{os.path.getsize(src)}\t{size}\t{status}"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", help="write each GLB under this folder, at the path of its mesh relative to its root")
    parser.add_argument("--strict", action="store_true", help="fail when a mesh cannot be converted")
    parser.add_argument("--jobs", type=int, default=1, help="convert this many meshes at once, which changes no byte of the output")
    parser.add_argument("roots", nargs="+")
    args = parser.parse_args()
    tasks = []
    for root in args.roots:
        if not os.path.isdir(root):
            continue
        for src, (package_dir, package_name, license_text) in find_meshes(root):
            rel = os.path.relpath(src, package_dir)
            dst = os.path.join(args.out, os.path.relpath(src, root) + ".glb") if args.out else src + ".glb"
            tasks.append((src, dst, package_name, rel, license_text))
    failures = 0
    with concurrent.futures.ProcessPoolExecutor(max_workers=max(1, args.jobs)) as executor:
        for line in executor.map(generate, *zip(*tasks)) if tasks else []:
            failures += line.rsplit("\t", 1)[-1].startswith("ERROR")
            print(line, flush=True)
    if failures:
        print(f"{failures} mesh(es) could not be converted.", file=sys.stderr)
    return 1 if (failures and args.strict) else 0


if __name__ == "__main__":
    sys.exit(main())
