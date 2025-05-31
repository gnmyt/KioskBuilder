#!/usr/bin/env python3
import os
import subprocess


def add_repository(chroot_dir, repo_name, repo_url, repo_key=None):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "add_repository.sh")

        cmd = [script_path, chroot_dir, repo_name, repo_url]
        if repo_key:
            cmd.append(repo_key)

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error adding repository {repo_name}: {str(e)}")
        return False


def install_package(chroot_dir, package_name, package_version=None):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "install_package.sh")

        cmd = [script_path, chroot_dir, package_name]
        if package_version:
            cmd.append(package_version)

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error installing package {package_name}: {str(e)}")
        return False


def setup_software(chroot_dir, software_config):
    try:
        repo_success = 0
        repositories = software_config.get('repositories', [])
        for repo in repositories:
            repo_name = repo.get('name')
            repo_url = repo.get('url')
            repo_key = repo.get('key')

            if not repo_name or not repo_url:
                print(f"Skipping invalid repository: {repo}")
                continue

            if add_repository(chroot_dir, repo_name, repo_url, repo_key):
                repo_success += 1

        print("Updating package lists...")
        update_cmd = ["chroot", chroot_dir, "apt-get", "update"]
        try:
            subprocess.run(update_cmd, check=False)
        except Exception as e:
            print(f"Warning: Failed to update package lists: {str(e)}")

        package_success = 0
        packages = software_config.get('packages', [])
        for package in packages:
            package_name = package.get('name')
            package_version = package.get('version')

            if not package_name:
                print(f"Skipping invalid package: {package}")
                continue

            if install_package(chroot_dir, package_name, package_version):
                package_success += 1

        print(
            f"Software configuration completed: {repo_success}/{len(repositories)} repositories and {package_success}/{len(packages)} packages configured successfully")
        return 0

    except Exception as e:
        print(f"Error setting up software: {str(e)}")
        return 1
