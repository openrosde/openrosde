#!/usr/bin/env python3
"""Check the file service of the robot model through 'rosbridge', the way Coarobo Viewport and Coarobo Sightline call it, as 'docs/robot-models.md' describes.

It connects to 'rosbridge' on 'ws://localhost:9090' and checks, with JSON calls that hold only 'op', 'id', 'service', and 'args':
- that '/rosapi/service_type' names the type of '/file_server/get_file', or no type with '--expect-no-service',
- that every GLB of a package of the Catkin workspaces, and some GLBs of every package installed in the image, come back byte for byte with their meshes, or empty when they exceed 'max_file_size',
- that no GLB of a package of the workspaces exceeds 'max_file_size', since a client could not load it,
- that an unknown package, a missing file, a path with '..', a file other than a mesh or a texture, and a 'file://' address are answered empty,
- that '/file_server/save_file' writes nothing,
- and that no response comes in fragments.
It needs only the Python of the image and 'tornado', which 'rosbridge_server' installs, since the test container has no network.

Usage: check-robot-model.py <workspace root> [<workspace root> ...] [--expect-no-service]
"""
import base64
import json
import os
import secrets
import sys
import xml.etree.ElementTree as ET

import rospkg
from tornado import ioloop, websocket

MAX_FILE_SIZE = 12000000
INSTALLED_SHARE_DIR = "/opt/ros/noetic/share"
GLBS_PER_INSTALLED_PACKAGE = 20
SKIPPED_FOLDERS = {"build", "devel", "install", "logs", ".git"}
MESH_SUFFIXES = (".dae.glb", ".stl.glb", ".obj.glb")


def find_glbs(root):
    # Yield every generated GLB under a root, with the folder and the name of its package.
    packages = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIPPED_FOLDERS)
        package = packages.get(os.path.dirname(dirpath))
        if "package.xml" in filenames:
            try:
                package = (dirpath, (ET.parse(os.path.join(dirpath, "package.xml")).getroot().findtext("name") or "").strip())
            except ET.ParseError:
                package = None
        packages[dirpath] = package
        if package is None:
            continue
        for filename in sorted(filenames):
            if filename.lower().endswith(MESH_SUFFIXES):
                yield os.path.join(dirpath, filename), package


class Client:
    def __init__(self, connection):
        self.connection = connection
        self.prefix = f"ci-{secrets.token_hex(6)}:"
        self.count = 0
        self.fragments = 0

    async def call(self, service, args):
        self.count += 1
        call_id = f"{self.prefix}{self.count}"
        await self.connection.write_message(json.dumps({"op": "call_service", "id": call_id, "service": service, "args": args}))
        while True:
            message = await self.connection.read_message()
            if message is None:
                raise RuntimeError("rosbridge closed the connection")
            message = json.loads(message)
            if message.get("op") == "fragment":
                self.fragments += 1
                continue
            if message.get("id") == call_id:
                return message

    async def get_file(self, name):
        response = await self.call("/file_server/get_file", {"name": name})
        if not response.get("result"):
            return False, b""
        return True, base64.b64decode(response.get("values", {}).get("value", ""))


async def check(roots, expect_no_service):
    failures = []
    connection = await websocket.websocket_connect("ws://localhost:9090", max_message_size=64 * 1024 * 1024)
    client = Client(connection)

    service_type = (await client.call("/rosapi/service_type", {"service": "/file_server/get_file"})).get("values", {}).get("type", "")
    if expect_no_service:
        print(f"'/rosapi/service_type' names '{service_type}' once the file service stops, where a client expects no type.")
        return [] if service_type == "" else ["the file service still answers after it stopped"]
    print(f"The file service '/file_server/get_file' has the type '{service_type}'.")
    if service_type != "file_server/GetBinaryFile":
        return ["the file service is missing or has another type"]

    # Gather the GLBs that the file service resolves to, skipping a package that another one of the same name shadows.
    rospack = rospkg.RosPack()
    checked = []
    oversized = []
    skipped = 0
    for root in roots + [INSTALLED_SHARE_DIR]:
        per_package = {}
        for path, (package_dir, package_name) in find_glbs(root):
            try:
                if os.path.realpath(rospack.get_path(package_name)) != os.path.realpath(package_dir):
                    continue
            except rospkg.ResourceNotFound:
                continue
            installed = root == INSTALLED_SHARE_DIR
            if os.path.getsize(path) > MAX_FILE_SIZE and not installed:
                oversized.append(path)
            per_package.setdefault(package_name, []).append((path, package_dir, package_name, installed))
        for entries in per_package.values():
            if entries[0][3]:
                # Every GLB above the limit is checked too, since its empty answer is part of the contract.
                kept = entries[:GLBS_PER_INSTALLED_PACKAGE] + [e for e in entries[GLBS_PER_INSTALLED_PACKAGE:] if os.path.getsize(e[0]) > MAX_FILE_SIZE]
                skipped += len(entries) - len(kept)
                entries = kept
            checked.extend(entries)
    print(f"Checking {len(checked)} GLBs and their meshes, all those of the workspaces and up to {GLBS_PER_INSTALLED_PACKAGE} of each installed package, and leaving out {skipped} other GLBs of installed packages.")

    largest = []
    for path, package_dir, package_name, _ in checked:
        uri = f"package://{package_name}/{os.path.relpath(path, package_dir)}"
        size = os.path.getsize(path)
        largest.append((size, uri))
        with open(path, "rb") as f:
            expected = f.read() if size <= MAX_FILE_SIZE else b""
        result, data = await client.get_file(uri)
        if not result or data != expected:
            failures.append(f"{uri} came back with {len(data)} bytes instead of {len(expected)}")
        mesh_path = path[: -len(".glb")]
        if os.path.exists(mesh_path) and os.path.getsize(mesh_path) <= MAX_FILE_SIZE:
            with open(mesh_path, "rb") as f:
                expected = f.read()
            result, data = await client.get_file(uri[: -len(".glb")])
            if not result or data != expected:
                failures.append(f"{uri[: -len('.glb')]} came back with {len(data)} bytes instead of {len(expected)}")

    for path in oversized:
        failures.append(f"{path} has {os.path.getsize(path)} bytes, above 'max_file_size' ({MAX_FILE_SIZE}), so no client can load it: simplify the mesh")

    # Check what the service refuses, with any package that the image holds.
    some_package = checked[0][2] if checked else "openrosde_launch"
    for name in [
        "package://no_such_package_of_openrosde/meshes/base.dae",
        f"package://{some_package}/no/such/mesh.dae",
        f"package://{some_package}/../../../../etc/passwd",
        f"package://{some_package}/package.xml",
        "file:///etc/passwd",
    ]:
        result, data = await client.get_file(name)
        if not result or data:
            failures.append(f"{name} was not answered with an empty value")
    save_name = f"package://{some_package}/meshes/openrosde-ci-saved.dae"
    await client.call("/file_server/save_file", {"name": save_name, "value": base64.b64encode(b"x").decode()})
    if os.path.exists(os.path.join(rospack.get_path(some_package), "meshes", "openrosde-ci-saved.dae")):
        failures.append("'/file_server/save_file' wrote a file")
    if client.fragments:
        failures.append(f"{client.fragments} responses came in fragments, which the core never sends")

    print("The largest responses:")
    for size, uri in sorted(largest, reverse=True)[:10]:
        print(f"  {size} bytes, {(size + 2) // 3 * 4} characters of base64: {uri}")
    return failures


def main():
    expect_no_service = "--expect-no-service" in sys.argv
    roots = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    failures = ioloop.IOLoop.current().run_sync(lambda: check(roots, expect_no_service), timeout=1800)
    for failure in failures:
        print(f"Error: {failure}")
    print("The robot model check passed." if not failures else f"The robot model check failed with {len(failures)} errors.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
