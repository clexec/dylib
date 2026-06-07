#!/usr/bin/env python3
"""
DouX IPA Injector
Injects DouX.dylib into TikTok IPA for Sideloadly / AltStore installation.

Requirements:
    pip install lief

Usage:
    python inject_ipa.py <TikTok.ipa or extracted folder> <DouX.dylib> [output.ipa]

Example:
    python inject_ipa.py "C:\\Users\\me\\Desktop\\DeTok" DouX.dylib TikTok-DouX.ipa
"""

import sys, os, shutil, zipfile, tempfile, struct

# ── dependency check ──────────────────────────────────────────────────────────
try:
    import lief
except ImportError:
    print("[*] Installing lief...")
    os.system(f'"{sys.executable}" -m pip install lief')
    import lief

DYLIB_NAME   = "DouX.dylib"
ELLEKIT_DIR  = "Ellekit.framework"   # folder next to this script

# ── helpers ───────────────────────────────────────────────────────────────────

def find_app(work_dir):
    payload = os.path.join(work_dir, "Payload")
    if not os.path.isdir(payload):
        raise SystemExit("❌  No 'Payload' folder found in IPA")
    apps = [f for f in os.listdir(payload) if f.endswith(".app")]
    if not apps:
        raise SystemExit("❌  No .app bundle found inside Payload/")
    return os.path.join(payload, apps[0]), apps[0].replace(".app", "")

def find_main_binary(app_dir, app_name):
    # Try the obvious path first
    candidate = os.path.join(app_dir, app_name)
    if os.path.isfile(candidate):
        return candidate
    # Scan for Mach-O arm64 binaries
    for f in os.listdir(app_dir):
        p = os.path.join(app_dir, f)
        if not os.path.isfile(p):
            continue
        try:
            with open(p, "rb") as fh:
                magic = fh.read(4)
            if magic in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe",
                         b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"):
                return p
        except Exception:
            pass
    raise SystemExit(f"❌  Could not find main binary in {app_dir}")

def already_injected(binary, dylib_path):
    for cmd in binary.commands:
        name = getattr(cmd, "name", None)
        if name and DYLIB_NAME in str(name):
            return True
    return False

def inject(binary_path):
    print(f"[*] Parsing {os.path.basename(binary_path)} ...")
    binary = lief.parse(binary_path)
    if binary is None:
        raise SystemExit(f"❌  lief could not parse {binary_path}")

    load_path = f"@executable_path/{DYLIB_NAME}"
    if already_injected(binary, load_path):
        print("[!] Already injected — skipping")
        return

    lib = lief.MachO.DylibCommand.create(load_path)
    binary.add(lib)
    binary.write(binary_path)
    print(f"[+] Injected {load_path}")

def bundle_ellekit(app_dir, script_dir):
    ellekit_src = os.path.join(script_dir, ELLEKIT_DIR)
    if not os.path.isdir(ellekit_src):
        print("[!] Ellekit.framework not found next to script — skipping")
        print("    Hooks will NOT work without a hooking library.")
        print("    Place Ellekit.framework folder next to inject_ipa.py and re-run.")
        return
    frameworks = os.path.join(app_dir, "Frameworks")
    os.makedirs(frameworks, exist_ok=True)
    dest = os.path.join(frameworks, ELLEKIT_DIR)
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(ellekit_src, dest)
    print(f"[+] Bundled {ELLEKIT_DIR}")

def repack(work_dir, output_path):
    print(f"[*] Repacking → {output_path} ...")
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as z:
        for root, _, files in os.walk(work_dir):
            for f in files:
                fp = os.path.join(root, f)
                z.write(fp, os.path.relpath(fp, work_dir))
    mb = os.path.getsize(output_path) / 1_048_576
    print(f"[+] Done — {output_path} ({mb:.0f} MB)")

# ── main ──────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    input_path  = sys.argv[1]
    dylib_path  = sys.argv[2]
    output_path = sys.argv[3] if len(sys.argv) > 3 else "TikTok-DouX.ipa"
    script_dir  = os.path.dirname(os.path.abspath(__file__))

    if not os.path.exists(input_path):
        raise SystemExit(f"❌  Not found: {input_path}")
    if not os.path.exists(dylib_path):
        raise SystemExit(f"❌  Not found: {dylib_path}")

    work = tempfile.mkdtemp(prefix="doux_")
    print(f"[*] Temp dir: {work}")

    try:
        # 1. Extract / copy IPA contents
        if os.path.isdir(input_path):
            print("[*] Using extracted folder ...")
            src_payload = os.path.join(input_path, "Payload")
            if os.path.isdir(src_payload):
                shutil.copytree(src_payload, os.path.join(work, "Payload"))
            else:
                # Might already be the Payload itself
                shutil.copytree(input_path, os.path.join(work, "Payload"))
        else:
            print("[*] Extracting IPA ...")
            with zipfile.ZipFile(input_path, "r") as z:
                z.extractall(work)

        app_dir, app_name = find_app(work)
        print(f"[*] App: {app_name}.app")

        # 2. Copy DouX.dylib into the app bundle
        shutil.copy2(dylib_path, os.path.join(app_dir, DYLIB_NAME))
        print(f"[+] Copied {DYLIB_NAME}")

        # 3. Bundle Ellekit (hooking library)
        bundle_ellekit(app_dir, script_dir)

        # 4. Inject load command into main binary
        binary_path = find_main_binary(app_dir, app_name)
        inject(binary_path)

        # 5. Repack
        repack(work, output_path)

        print()
        print("=" * 55)
        print("  INSTALL INSTRUCTIONS")
        print("=" * 55)
        print(f"  1. Open Sideloadly")
        print(f"  2. Drag '{output_path}' into Sideloadly")
        print(f"  3. Enter your Apple ID")
        print(f"  4. Click Start")
        print(f"  5. Trust certificate on iPhone:")
        print(f"     Settings → General → VPN & Device Management")
        print("=" * 55)

    finally:
        shutil.rmtree(work, ignore_errors=True)

if __name__ == "__main__":
    main()
