"""Publish world-mode-bridge to the Factorio mod portal.

Usage:
    python scripts/publish-mod.py          # Upload new release
    python scripts/publish-mod.py --init   # First-time publish (already done for v0.1.0)
"""

import json
import os
import sys
import urllib.request
import urllib.error
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOD_DIR = os.path.join(ROOT, "mod", "world-mode-bridge")
SECRETS_FILE = os.path.join(ROOT, ".secrets")
BUILD_DIR = os.path.join(ROOT, "build")
MOD_NAME = "world-mode-bridge"

SKIP_FILES = {".gitattributes", ".gitignore"}


def load_api_key():
    with open(SECRETS_FILE) as f:
        for line in f:
            if line.startswith("FACTORIO_API_KEY="):
                return line.strip().split("=", 1)[1]
    raise RuntimeError("FACTORIO_API_KEY not found in .secrets")


def get_version():
    with open(os.path.join(MOD_DIR, "info.json")) as f:
        return json.load(f)["version"]


def package(version):
    folder = f"{MOD_NAME}_{version}"
    os.makedirs(BUILD_DIR, exist_ok=True)
    zip_path = os.path.join(BUILD_DIR, f"{folder}.zip")

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(MOD_DIR):
            for file in files:
                if file in SKIP_FILES:
                    continue
                full = os.path.join(root, file)
                arc = os.path.join(folder, os.path.relpath(full, MOD_DIR))
                zf.write(full, arc)
                print(f"  + {arc}")

    size = os.path.getsize(zip_path)
    print(f"Packaged: {zip_path} ({size:,} bytes)")
    return zip_path


def multipart_form(fields, files):
    boundary = "----PythonPublishBoundary9X2mK"
    parts = []
    for name, value in fields.items():
        parts.append(f"--{boundary}".encode())
        parts.append(f'Content-Disposition: form-data; name="{name}"'.encode())
        parts.append(b"")
        parts.append(value.encode() if isinstance(value, str) else value)
    for name, (filename, data, content_type) in files.items():
        parts.append(f"--{boundary}".encode())
        parts.append(f'Content-Disposition: form-data; name="{name}"; filename="{filename}"'.encode())
        parts.append(f"Content-Type: {content_type}".encode())
        parts.append(b"")
        parts.append(data)
    parts.append(f"--{boundary}--".encode())
    body = b"\r\n".join(parts)
    content_type = f"multipart/form-data; boundary={boundary}"
    return body, content_type


def api_post(url, body, content_type, auth=None):
    req = urllib.request.Request(url, method="POST")
    req.add_header("Content-Type", content_type)
    if auth:
        req.add_header("Authorization", f"Bearer {auth}")
    req.data = body
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}")
        sys.exit(1)


def publish(api_key, zip_path, version, init=False):
    # Step 1: Get upload URL
    if init:
        url = "https://mods.factorio.com/api/v2/mods/init_publish"
        print("First-time publish...")
    else:
        url = "https://mods.factorio.com/api/v2/mods/releases/init_upload"
        print("Uploading new release...")

    body, ct = multipart_form({"mod": MOD_NAME}, {})
    result = api_post(url, body, ct, auth=api_key)
    upload_url = result.get("upload_url")
    if not upload_url:
        print(f"No upload_url: {result}")
        sys.exit(1)

    # Step 2: Upload zip
    with open(zip_path, "rb") as f:
        zip_data = f.read()

    filename = os.path.basename(zip_path)
    body2, ct2 = multipart_form({}, {"file": (filename, zip_data, "application/zip")})
    result2 = api_post(upload_url, body2, ct2)

    if result2.get("success"):
        print(f"\nPublished {MOD_NAME} v{version}!")
        print(f"https://mods.factorio.com/mod/{MOD_NAME}")
    else:
        print(f"Upload failed: {result2}")
        sys.exit(1)


def main():
    init = "--init" in sys.argv
    api_key = load_api_key()
    version = get_version()
    print(f"Publishing {MOD_NAME} v{version}...")
    zip_path = package(version)
    publish(api_key, zip_path, version, init=init)

    # Cleanup
    import shutil
    shutil.rmtree(BUILD_DIR, ignore_errors=True)


if __name__ == "__main__":
    main()
