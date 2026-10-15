#!/usr/bin/env python3
"""Convert one mesh of a robot description, COLLADA, STL, or OBJ, into a GLB.

The GLB holds the mesh as RViz places it in the frame of the URDF <visual> or <collision>:
- the COLLADA <unit meter> scale and node transforms are kept, as node matrices,
- the COLLADA <up_axis> is ignored, as RViz does,
- the URDF <origin> and <mesh scale> are not applied, since the client applies them in the URDF axes,
then turned from the ROS link frame (Z up) into glTF (Y up) by R_x(-90 deg), so glTF (x, y, z) = ROS (x, z, -y).
COLLADA comes out in meters, while STL and OBJ carry no unit, so their numbers pass through unchanged and the URDF <mesh scale> converts them, as it does for the original file.
An STL becomes bare positions, with no normals, no material, and no vertex colors, so the client draws flat normals and the URDF <material>.
COLLADA and MTL colors are written as linear baseColorFactor values, as glTF requires, with their textures embedded.
COLLADA <lines> primitives (edges) are dropped by the loader of trimesh.
The asset of the GLB names its generator, a copyright line, and in 'extras' the package, the source URI, the license, and the SHA-256 of the source.

Usage: mesh2glb.py <input mesh> <output .glb> [<package> <source URI> <license>]
"""
import hashlib
import os
import sys
import xml.etree.ElementTree as ET

import numpy as np
import trimesh

# The generator written into every GLB, which 'generate-mesh-glbs.py' compares to decide whether a GLB is current.
# Change it whenever the output of this script changes, so that every GLB is regenerated.
GENERATOR = "OpenRoSDE mesh2glb 1.0.0"

ROS_TO_GLTF = trimesh.transformations.rotation_matrix(-np.pi / 2.0, [1.0, 0.0, 0.0])


def collada_unit(path):
    # <COLLADA><asset><unit meter="..."/>, 1.0 when absent or empty, as the COLLADA schema defaults it.
    root = ET.parse(path).getroot()
    for asset in root:
        if asset.tag.split("}", 1)[-1] == "asset":
            for el in asset:
                if el.tag.split("}", 1)[-1] == "unit" and el.get("meter"):
                    return float(el.get("meter"))
    return 1.0


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linearize_base_colors(tree):
    # glTF baseColorFactor is linear, while COLLADA and MTL colors are display (sRGB) values, which is how the three.js ColladaLoader reads them.
    for mat in tree.get("materials", []):
        pbr = mat.get("pbrMetallicRoughness", {})
        if "baseColorFactor" in pbr:
            r, g, b, a = pbr["baseColorFactor"]
            pbr["baseColorFactor"] = [round(srgb_to_linear(r), 6), round(srgb_to_linear(g), 6), round(srgb_to_linear(b), 6), a]


def strip_stl_attributes(tree):
    # A primitive with positions alone lets the client draw flat normals and apply the URDF <material>.
    for mesh in tree.get("meshes", []):
        for prim in mesh.get("primitives", []):
            prim.pop("material", None)
            prim["attributes"] = {"POSITION": prim["attributes"]["POSITION"]}
    tree.pop("materials", None)


def clean(mesh):
    """Drops zero-area triangles and gives every vertex a unit normal, keeping the normals of the file and repairing only zero or non-unit ones."""
    v = mesh.vertices
    f = mesh.faces
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    length = np.linalg.norm(fn, axis=1)
    keep = length > 0.0
    if not keep.all():
        mesh.update_faces(keep)
        mesh.remove_unreferenced_vertices()
        v = mesh.vertices
        f = mesh.faces
        fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
        length = np.linalg.norm(fn, axis=1)
    fn = fn / length[:, None]
    n = np.array(mesh.vertex_normals, dtype=float)
    nl = np.linalg.norm(n, axis=1)
    bad = nl < 0.5
    if bad.any():
        for k in range(3):
            idx = f[:, k]
            sel = bad[idx]
            n[idx[sel]] = fn[sel]
        nl = np.linalg.norm(n, axis=1)
    n = n / nl[:, None]
    mesh.vertex_normals = n


def describe_asset(tree, src, package, uri, license_text):
    asset = tree.setdefault("asset", {})
    asset["version"] = "2.0"
    asset["generator"] = GENERATOR
    with open(src, "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    asset["copyright"] = f"Converted from {uri or os.path.basename(src)}, under the license of the package {package or 'that holds it'}: {license_text or 'see its package.xml'}"
    asset["extras"] = {"package": package, "source": uri, "license": license_text, "sha256": digest}


def convert(src, dst, package="", uri="", license_text=""):
    ext = os.path.splitext(src)[1].lower()
    name = os.path.basename(src)
    post = [linearize_base_colors]
    include_normals = True
    if ext == ".dae":
        scene = trimesh.load(src, force="scene", process=False)
        unit = collada_unit(src)
        scene.apply_transform(ROS_TO_GLTF @ np.diag([unit, unit, unit, 1.0]))
    elif ext == ".stl":
        mesh = trimesh.load(src, force="mesh", process=False)
        mesh.visual = trimesh.visual.ColorVisuals(mesh=mesh)
        scene = trimesh.Scene()
        scene.add_geometry(mesh, geom_name=name, node_name=name)
        scene.apply_transform(ROS_TO_GLTF)
        post = [strip_stl_attributes]
        include_normals = False
    elif ext == ".obj":
        scene = trimesh.load(src, force="scene", process=False)
        scene.apply_transform(ROS_TO_GLTF)
    else:
        raise SystemExit(f"unsupported mesh format: {src}")
    if include_normals:
        for geom in scene.geometry.values():
            if isinstance(geom, trimesh.Trimesh) and len(geom.faces):
                clean(geom)

    def postprocess(tree):
        for step in post:
            step(tree)
        describe_asset(tree, src, package, uri, license_text)

    data = scene.export(file_type="glb", include_normals=include_normals, tree_postprocessor=postprocess)
    tmp = dst + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, dst)


if __name__ == "__main__":
    convert(*sys.argv[1:6])
