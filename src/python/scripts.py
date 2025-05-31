#!/usr/bin/env python3
import os
import subprocess


def execute_script(chroot_dir, script_name, script_content, script_type, execute=True):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "execute_single_script.sh")

        cmd = [script_path, chroot_dir, script_name, script_content, script_type]

        if not execute:
            cmd.append("install_only")

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error executing script {script_name}: {str(e)}")
        return False


def setup_startup_service(chroot_dir):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "setup_startup_service.sh")

        cmd = [script_path, chroot_dir, "startup"]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error setting up startup service: {str(e)}")
        return False


def execute_scripts(chroot_dir, scripts, script_type, execute=True):
    success_count = 0
    scripts = scripts.get(script_type, [])

    for script in scripts:
        script_name = script.get('name')
        script_content = script.get('content')

        if not script_content or script_content == "null":
            print(f"Skipping empty script: {script_name}")
            continue

        if execute_script(chroot_dir, script_name, script_content, script_type, execute):
            success_count += 1

    if script_type == "startup":
        setup_startup_service(chroot_dir)

    if execute:
        print(f"{script_type} scripts execution completed ({success_count}/{len(scripts)} successful)")
    else:
        print(f"{script_type} scripts installation completed ({success_count}/{len(scripts)} successful)")

    return 0
