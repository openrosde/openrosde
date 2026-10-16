#!/usr/bin/env python3
"""Check the file service of the robot model through 'rosbridge', the way Coarobo Viewport and Coarobo Sightline call it, as 'docs/robot-models.md' describes.

It connects to 'rosbridge' on 'ws://localhost:9090' and checks, with JSON calls that hold only 'op', 'id', 'service', and 'args':
- that '/rosapi/service_type' names the type of '/file_server/get_file', 'file_server/GetBinaryFile' on ROS 1 or 'file_server2/srv/GetBinaryFile' on ROS 2, or no type with '--expect-no-service',
- that every GLB of a package of the Catkin or colcon workspaces, and some GLBs of every package installed in the image, come back byte for byte with their meshes, or empty when they exceed 'max_file_size',
- that no GLB of a package of the workspaces exceeds 'max_file_size', since a client could not load it, unless its mesh lies in a Git submodule, third-party code that a platform pins and cannot simplify, which is reported,
- that an unknown package, a missing file, a path with '..', a file other than a mesh or a texture, and a 'file://' address are answered empty,
- that '/file_server/save_file' writes nothing,
- and that no response comes in fragments, or, with '--fragments', that every GLB of 1,000,000 bytes or more comes in 'fragment' messages that a client reassembles by 'id', 'num', and 'total' into the same bytes, from a 'rosbridge' that fragments above 'max_message_size' 1,000,000.
On ROS 1 it finds the packages with 'rospkg' from 'package.xml' under the roots, and on ROS 2 from the index of 'ament', as the file service resolves them, a package under a root being one of the workspaces.
It needs only the Python of the image and 'tornado', which 'rosbridge_server' installs, since the test container has no network.

Usage: check-robot-model.py <workspace root> [<workspace root> ...] [--expect-no-service] [--fragments]
"""
import base64
import json
import math
import os
import secrets
import sys
import xml.etree.ElementTree as ET

from tornado import ioloop, websocket

ROS_VERSION = os.environ.get("ROS_VERSION", "1")
MAX_FILE_SIZE = 12000000
INSTALLED_SHARE_DIR = f"/opt/ros/{os.environ.get('ROS_DISTRO', 'noetic')}/share"
SERVICE_TYPE = "file_server2/srv/GetBinaryFile" if ROS_VERSION == "2" else "file_server/GetBinaryFile"
FRAGMENTED_FILE_SIZE = 1000000
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


def find_ament_glbs(roots):
    # Yield every generated GLB of every package of the index of 'ament', with the share folder and the name of its package, and whether it lies under a root.
    from ament_index_python.packages import get_packages_with_prefixes

    real_roots = [os.path.realpath(root) + os.sep for root in roots]
    for package_name, prefix in sorted(get_packages_with_prefixes().items()):
        package_dir = os.path.join(prefix, "share", package_name)
        for dirpath, dirnames, filenames in os.walk(package_dir):
            dirnames[:] = sorted(d for d in dirnames if d not in SKIPPED_FOLDERS)
            for filename in sorted(filenames):
                if filename.lower().endswith(MESH_SUFFIXES):
                    path = os.path.join(dirpath, filename)
                    yield path, (package_dir, package_name), any(os.path.realpath(path).startswith(root) for root in real_roots)


def find_source_dirs(roots):
    # Map the name of every package under the roots to its source folder, the one that holds its 'package.xml', outside the build, devel, install, and log spaces.
    source_dirs = {}
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = sorted(d for d in dirnames if d not in SKIPPED_FOLDERS and d != "log")
            if "package.xml" in filenames:
                try:
                    name = (ET.parse(os.path.join(dirpath, "package.xml")).getroot().findtext("name") or "").strip()
                except ET.ParseError:
                    continue
                source_dirs.setdefault(name, dirpath)
    return source_dirs


def in_git_submodule(path, roots):
    # Tell whether a path lies in a Git submodule under a root, whose folder holds a '.git' file, where a clone holds a '.git' folder.
    real_roots = {os.path.realpath(root) for root in roots}
    directory = os.path.dirname(os.path.realpath(path))
    while directory not in real_roots and directory != os.path.dirname(directory):
        if os.path.isfile(os.path.join(directory, ".git")):
            return True
        directory = os.path.dirname(directory)
    return False


class Client:
    def __init__(self, connection):
        self.connection = connection
        self.prefix = f"ci-{secrets.token_hex(6)}:"
        self.count = 0
        self.fragments = 0
        self.fragmented_ids = set()

    async def call(self, service, args):
        # Reassemble the 'fragment' messages of the response by 'id', 'num' from 0, and 'total', as a client of a stock 'rosbridge' does.
        self.count += 1
        call_id = f"{self.prefix}{self.count}"
        await self.connection.write_message(json.dumps({"op": "call_service", "id": call_id, "service": service, "args": args}))
        fragments = {}
        while True:
            message = await self.connection.read_message()
            if message is None:
                raise RuntimeError("rosbridge closed the connection")
            message = json.loads(message)
            if message.get("op") == "fragment":
                self.fragments += 1
                if message.get("id") != call_id:
                    continue
                fragments[int(message["num"])] = message["data"]
                if len(fragments) < math.ceil(float(message["total"])):
                    continue
                message = json.loads("".join(fragments[num] for num in sorted(fragments)))
                self.fragmented_ids.add(call_id)
            if message.get("id") == call_id:
                return message

    async def get_file(self, name):
        response = await self.call("/file_server/get_file", {"name": name})
        if not response.get("result"):
            return False, b""
        return True, base64.b64decode(response.get("values", {}).get("value", ""))


async def check(roots, expect_no_service, expect_fragments):
    failures = []
    connection = await websocket.websocket_connect("ws://localhost:9090", max_message_size=64 * 1024 * 1024)
    client = Client(connection)

    service_type = (await client.call("/rosapi/service_type", {"service": "/file_server/get_file"})).get("values", {}).get("type", "")
    if expect_no_service:
        print(f"'/rosapi/service_type' names '{service_type}' once the file service stops, where a client expects no type.")
        return [] if service_type == "" else ["the file service still answers after it stopped"]
    print(f"The file service '/file_server/get_file' has the type '{service_type}'.")
    if service_type != SERVICE_TYPE:
        return ["the file service is missing or has another type"]

    # Gather the GLBs that the file service resolves to: on ROS 1, under the roots and the installed packages, skipping a package that another one of the same name shadows, and on ROS 2, of every package of the index of 'ament', where a package under no root and outside the installed packages is checked in full, as a package of a workspace is.
    if ROS_VERSION == "2":
        found = []
        for path, package, under_root in find_ament_glbs(roots):
            installed = not under_root and package[0].startswith(INSTALLED_SHARE_DIR + os.sep)
            found.append((path, package, installed, under_root))
        sources = [(None, found)]
    else:
        import rospkg

        rospack = rospkg.RosPack()
        sources = [(root, find_glbs(root)) for root in roots + [INSTALLED_SHARE_DIR]]
    checked = []
    oversized = []
    third_party_oversized = []
    skipped = 0
    source_dirs = find_source_dirs(roots) if ROS_VERSION == "2" else {}
    for root, glbs in sources:
        per_package = {}
        for entry in glbs:
            if root is None:
                path, (package_dir, package_name), installed, in_workspace = entry
            else:
                path, (package_dir, package_name) = entry
                try:
                    if os.path.realpath(rospack.get_path(package_name)) != os.path.realpath(package_dir):
                        continue
                except rospkg.ResourceNotFound:
                    continue
                installed = root == INSTALLED_SHARE_DIR
                in_workspace = not installed
            if os.path.getsize(path) > MAX_FILE_SIZE and in_workspace:
                source_path = os.path.join(source_dirs.get(package_name, package_dir), os.path.relpath(path, package_dir))
                (third_party_oversized if in_git_submodule(source_path, roots) else oversized).append(path)
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

    for path in third_party_oversized:
        print(f"Warning: {path} has {os.path.getsize(path)} bytes, above 'max_file_size' ({MAX_FILE_SIZE}), in a Git submodule, so clients fall back to the collision mesh of its link.")
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
    if ROS_VERSION == "2":
        from ament_index_python.packages import get_package_share_directory

        some_package_dir = get_package_share_directory(some_package)
    else:
        some_package_dir = rospack.get_path(some_package)
    if os.path.exists(os.path.join(some_package_dir, "meshes", "openrosde-ci-saved.dae")):
        failures.append("'/file_server/save_file' wrote a file")
    if expect_fragments:
        large = [entry for entry in checked if FRAGMENTED_FILE_SIZE <= os.path.getsize(entry[0]) <= MAX_FILE_SIZE]
        print(f"{len(client.fragmented_ids)} responses came in {client.fragments} fragments, which the check reassembled, for {len(large)} GLBs of 1,000,000 bytes or more.")
        if not large:
            failures.append("no GLB of 1,000,000 bytes or more was found, so no response could come in fragments")
        elif len(client.fragmented_ids) < len(large):
            failures.append(f"only {len(client.fragmented_ids)} responses came in fragments, for {len(large)} GLBs of 1,000,000 bytes or more")
    elif client.fragments:
        failures.append(f"{client.fragments} responses came in fragments, which the core never sends")

    print("The largest responses:")
    for size, uri in sorted(largest, reverse=True)[:10]:
        print(f"  {size} bytes, {(size + 2) // 3 * 4} characters of base64: {uri}")
    return failures


def main():
    expect_no_service = "--expect-no-service" in sys.argv
    expect_fragments = "--fragments" in sys.argv
    roots = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    failures = ioloop.IOLoop.current().run_sync(lambda: check(roots, expect_no_service, expect_fragments), timeout=1800)
    for failure in failures:
        print(f"Error: {failure}")
    print("The robot model check passed." if not failures else f"The robot model check failed with {len(failures)} errors.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
