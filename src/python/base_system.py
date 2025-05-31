#!/usr/bin/env python3
import os
import subprocess


def setup_base_system(build_dir):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

    script_path = os.path.join(bash_dir, "setup_base_system.sh")
    cmd = [script_path, build_dir]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in iter(process.stdout.readline, ''):
        if not line:
            break
        print(line, end='')

    return process.wait()
