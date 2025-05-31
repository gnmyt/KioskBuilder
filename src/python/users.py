#!/usr/bin/env python3
import os
import subprocess


def create_user_in_chroot(chroot_dir, username, password, groups=None, sudo=False):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
        script_path = os.path.join(bash_dir, "configure_users.sh")

        group_str = ""
        if groups and groups != "null" and isinstance(groups, list) and groups:
            group_str = ",".join(groups)

        sudo_str = "true" if sudo else "false"

        cmd = [script_path, chroot_dir, username, password, group_str, sudo_str, "false"]

        process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

        if process.stdout:
            print(process.stdout)

        return process.returncode == 0
    except Exception as e:
        print(f"Error creating user {username}: {str(e)}")
        return False


def configure_autologin(chroot_dir, username, password="changeme"):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
        script_path = os.path.join(bash_dir, "configure_users.sh")

        cmd = [script_path, chroot_dir, username, password, "", "false", "true"]

        process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

        if process.stdout:
            print(process.stdout)

        return process.returncode == 0
    except Exception as e:
        print(f"Error configuring autologin for {username}: {str(e)}")
        return False


def setup_users(chroot_dir, users_list):
    try:
        for user in users_list:
            username = user.get('name')
            password = user.get('password', 'changeme')
            groups = user.get('groups', [])
            sudo = user.get('sudo', False)
            autologin = user.get('autologin', False)

            if not create_user_in_chroot(chroot_dir, username, password, groups, sudo):
                print(f"Warning: Failed to create or configure user {username}")
                continue

            if autologin:
                if not configure_autologin(chroot_dir, username, password):
                    print(f"Warning: Failed to configure autologin for user {username}")

        return True
    except Exception as e:
        print(f"Error setting up users directly: {str(e)}")
        return False
