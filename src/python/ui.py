#!/usr/bin/env python3
import os
import subprocess


def install_ui_packages(chroot_dir):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "install_ui_packages.sh")
        cmd = [script_path, chroot_dir]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error installing UI packages: {str(e)}")
        return False


def configure_kiosk_mode(chroot_dir, kiosk_app, resolution=None, orientation=None):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "configure_kiosk_mode.sh")

        cmd = [script_path, chroot_dir, kiosk_app]
        if resolution:
            cmd.append(resolution)
        else:
            cmd.append("null")

        if orientation:
            cmd.append(str(orientation))
        else:
            cmd.append("null")

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error configuring kiosk mode: {str(e)}")
        return False


def setup_ui(chroot_dir, ui_config):
    try:
        if not install_ui_packages(chroot_dir):
            print("Warning: Failed to install UI packages")

        kiosk_config = ui_config.get('kiosk_mode', {})
        display_config = ui_config.get('display', {})

        if kiosk_config:
            kiosk_app = kiosk_config.get('application')
            resolution = display_config.get('resolution')
            orientation = display_config.get('orientation', 0)

            if kiosk_app:
                if not configure_kiosk_mode(chroot_dir, kiosk_app, resolution, orientation):
                    print("Warning: Failed to configure kiosk mode")
            else:
                print("Warning: No kiosk application specified")

        print("UI configuration completed successfully")
        return 0

    except Exception as e:
        print(f"Error setting up UI: {str(e)}")
        return 1
