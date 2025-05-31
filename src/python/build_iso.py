#!/usr/bin/env python3
import os
import subprocess


def build_iso(build_dir, config, output_dir):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
    chroot_dir = os.path.join(build_dir, "chroot")

    if isinstance(config, dict):
        system_name = config.get('system_name', 'kiosk')
    else:
        import yaml
        try:
            with open(config, 'r') as f:
                cfg = yaml.safe_load(f)
                system_name = cfg.get('system_name', 'kiosk')
        except Exception as e:
            print(f"Warning: Could not read system name from config: {e}")
            system_name = "kiosk"

    os.makedirs(output_dir, exist_ok=True)

    script_path = os.path.join(bash_dir, "build_iso.sh")
    cmd = [script_path, build_dir, chroot_dir, system_name, output_dir]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in iter(process.stdout.readline, ''):
        if not line:
            break
        print(line, end='')

    return process.wait()
