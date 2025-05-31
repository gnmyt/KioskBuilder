#!/usr/bin/env python3
import yaml


def load_config(config_path):
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def validate_config(config):
    if 'system_config' in config:
        system_config = config['system_config']

        if 'network' in system_config:
            network_config = system_config['network']
            if 'type' not in network_config:
                print("Warning: Network type not specified, defaulting to 'dhcp'")
            elif network_config['type'] not in ['dhcp', 'static']:
                raise ValueError("Network type must be 'dhcp' or 'static'")

            if network_config.get('type') == 'static':
                if 'static_config' not in network_config:
                    raise ValueError("Static network configuration requires 'static_config' section")

                static_config = network_config['static_config']
                if 'ip' not in static_config:
                    raise ValueError("Static network configuration requires 'ip' address")
                if 'gateway' not in static_config:
                    raise ValueError("Static network configuration requires 'gateway' address")

        if 'updates' in system_config:
            updates_config = system_config['updates']
            if 'automatic' in updates_config and updates_config['automatic'] and 'schedule' not in updates_config:
                print(
                    "Warning: Automatic updates enabled but no schedule specified, defaulting to '0 2 * * *' (2 AM daily)")

        if 'locale' in system_config:
            locale_config = system_config['locale']
            if 'language' not in locale_config:
                print("Warning: Locale language not specified, defaulting to 'en_US.UTF-8'")
            if 'keyboard' not in locale_config:
                print("Warning: Keyboard layout not specified, defaulting to 'us'")

        if 'timezone' not in system_config:
            print("Warning: Timezone not specified, defaulting to 'UTC'")

    if 'security' in config:
        security_config = config['security']

        if 'firewall' in security_config:
            firewall_config = security_config['firewall']
            if 'enabled' not in firewall_config:
                print("Warning: Firewall enabled status not specified, defaulting to disabled")
            if 'allow_ports' in firewall_config and not isinstance(firewall_config['allow_ports'], list):
                raise ValueError("Firewall allowed ports must be a list of integers")

        if 'ssh' in security_config:
            ssh_config = security_config['ssh']
            if 'enabled' not in ssh_config:
                print("Warning: SSH enabled status not specified, defaulting to disabled")

        if 'file_permissions' in security_config:
            file_permissions = security_config['file_permissions']
            if not isinstance(file_permissions, list):
                raise ValueError("File permissions must be a list")
            
            for i, perm in enumerate(file_permissions):
                if 'path' not in perm:
                    raise ValueError(f"File permission entry {i} is missing required 'path' field")

    if 'users' not in config:
        raise ValueError("No users defined in config")

    if 'software' not in config:
        raise ValueError("No software defined in config")

    if 'ui' not in config:
        raise ValueError("No UI configuration defined in config")

    if 'scripts' in config:
        scripts = config.get('scripts', {})
        valid_script_types = ['pre_install', 'post_install', 'startup']

        for script_type, scripts_list in scripts.items():
            if script_type not in valid_script_types:
                print(f"Warning: Unknown script type '{script_type}'. Valid types are: {', '.join(valid_script_types)}")
                continue

            if not isinstance(scripts_list, list):
                raise ValueError(f"Scripts in '{script_type}' must be a list")

            for i, script in enumerate(scripts_list):
                if not isinstance(script, dict):
                    raise ValueError(f"Script {i} in '{script_type}' must be an object")

                if 'name' not in script:
                    print(f"Warning: Script {i} in '{script_type}' has no name")

                if 'content' not in script:
                    raise ValueError(f"Script '{script.get('name', i)}' in '{script_type}' has no content")

    return True
