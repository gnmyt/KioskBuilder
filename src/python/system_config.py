#!/usr/bin/env python3
import os
import subprocess


def configure_hostname(chroot_dir, hostname):
    try:
        if not hostname:
            print("Warning: No hostname specified, using default 'kiosk'")
            hostname = "kiosk"

        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "configure_hostname.sh")
        cmd = [script_path, chroot_dir, hostname]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error configuring hostname: {str(e)}")
        return False


def configure_network(chroot_dir, network_config):
    try:
        if not network_config:
            print("Warning: No network configuration specified, using DHCP")
            network_type = "dhcp"
        else:
            network_type = network_config.get('type', 'dhcp')

        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "configure_network.sh")

        cmd = [script_path, chroot_dir, network_type]

        if network_type == "static":
            static_config = network_config.get('static_config', {})
            ip_address = static_config.get('ip')
            gateway = static_config.get('gateway')

            if not ip_address or not gateway:
                print("Error: Static network configuration requires IP address and gateway")
                return False

            cmd.append(ip_address)
            cmd.append(gateway)

            dns_servers = static_config.get('dns', [])
            if dns_servers:
                if isinstance(dns_servers, list):
                    cmd.append(','.join(dns_servers))
                else:
                    cmd.append(dns_servers)
            else:
                cmd.append("")

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error configuring network: {str(e)}")
        return False


def configure_updates(chroot_dir, updates_config):
    try:
        if not updates_config:
            print("Warning: No updates configuration specified, disabling automatic updates")
            automatic = "false"
            schedule = ""
        else:
            automatic = "true" if updates_config.get('automatic', False) else "false"
            schedule = updates_config.get('schedule', "0 2 * * *")

        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "configure_updates.sh")

        cmd = [script_path, chroot_dir, automatic]
        if automatic == "true":
            cmd.append(schedule)

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error configuring updates: {str(e)}")
        return False


def configure_locale(chroot_dir, locale_config, timezone):
    try:
        if not locale_config:
            print("Warning: No locale configuration specified, using defaults")
            language = "en_US.UTF-8"
            keyboard = "us"
        else:
            language = locale_config.get('language', "en_US.UTF-8")
            keyboard = locale_config.get('keyboard', "us")

        if not timezone:
            print("Warning: No timezone specified, using default (UTC)")
            timezone = "UTC"

        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")

        script_path = os.path.join(bash_dir, "configure_locale.sh")

        cmd = [script_path, chroot_dir, language, keyboard, timezone]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')

        return process.wait() == 0

    except Exception as e:
        print(f"Error configuring locale: {str(e)}")
        return False


def setup_system_config(chroot_dir, system_config):
    try:
        success_count = 0
        total_count = 0

        total_count += 1
        hostname = system_config.get('hostname')
        if configure_hostname(chroot_dir, hostname):
            success_count += 1

        total_count += 1
        network_config = system_config.get('network')
        if configure_network(chroot_dir, network_config):
            success_count += 1

        total_count += 1
        updates_config = system_config.get('updates')
        if configure_updates(chroot_dir, updates_config):
            success_count += 1

        total_count += 1
        locale_config = system_config.get('locale')
        timezone = system_config.get('timezone')
        if configure_locale(chroot_dir, locale_config, timezone):
            success_count += 1

        print(f"System configuration completed: {success_count}/{total_count} components configured successfully")
        return 0

    except Exception as e:
        print(f"Error setting up system configuration: {str(e)}")
        return 1
