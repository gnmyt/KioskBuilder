#!/usr/bin/env python3
import os
import subprocess

def configure_firewall(chroot_dir, firewall_config):
    try:
        if not firewall_config:
            print("Warning: No firewall configuration specified, disabling firewall")
            enabled = "false"
            allow_ports = ""
        else:
            enabled = "true" if firewall_config.get('enabled', False) else "false"
            allow_ports = firewall_config.get('allow_ports', [])
            if allow_ports and isinstance(allow_ports, list):
                allow_ports = ",".join(map(str, allow_ports))
            else:
                allow_ports = ""
        
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
        
        script_path = os.path.join(bash_dir, "configure_firewall.sh")
        cmd = [script_path, chroot_dir, enabled, allow_ports]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')
        
        return process.wait() == 0
    
    except Exception as e:
        print(f"Error configuring firewall: {str(e)}")
        return False

def configure_ssh(chroot_dir, ssh_config):
    try:
        if not ssh_config:
            print("Warning: No SSH configuration specified, disabling SSH")
            enabled = "false"
            allow_root_login = "false"
            password_authentication = "false"
        else:
            enabled = "true" if ssh_config.get('enabled', False) else "false"
            allow_root_login = "true" if ssh_config.get('allow_root_login', False) else "false"
            password_authentication = "true" if ssh_config.get('password_authentication', True) else "false"
        
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
        
        script_path = os.path.join(bash_dir, "configure_ssh.sh")
        cmd = [script_path, chroot_dir, enabled, allow_root_login, password_authentication]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')
        
        return process.wait() == 0
    
    except Exception as e:
        print(f"Error configuring SSH: {str(e)}")
        return False

def set_file_permissions(chroot_dir, path, owner, group, mode):
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        bash_dir = os.path.join(os.path.dirname(script_dir), "bash")
        
        script_path = os.path.join(bash_dir, "set_file_permissions.sh")
        cmd = [script_path, chroot_dir, path, owner, group, mode]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in iter(process.stdout.readline, ''):
            if not line:
                break
            print(line, end='')
        
        return process.wait() == 0
    
    except Exception as e:
        print(f"Error setting file permissions for {path}: {str(e)}")
        return False

def configure_file_permissions(chroot_dir, file_permissions_config):
    try:
        if not file_permissions_config or not isinstance(file_permissions_config, list):
            print("No file permission configurations specified")
            return True
        
        success_count = 0
        for perm in file_permissions_config:
            path = perm.get('path')
            owner = perm.get('owner', 'root')
            group = perm.get('group', 'root')
            mode = perm.get('mode', '0644')
            
            if not path:
                print("Warning: Missing path in file permission configuration, skipping")
                continue
                
            if set_file_permissions(chroot_dir, path, owner, group, mode):
                success_count += 1
            else:
                print(f"Warning: Failed to set permissions for {path}")
        
        print(f"File permissions configuration completed: {success_count}/{len(file_permissions_config)} successful")
        return success_count == len(file_permissions_config)
    
    except Exception as e:
        print(f"Error configuring file permissions: {str(e)}")
        return False

def setup_security(chroot_dir, security_config):
    try:
        if not security_config:
            print("No security configuration provided, skipping security setup")
            return True
        
        success_count = 0
        total_count = 0

        total_count += 1
        firewall_config = security_config.get('firewall')
        if configure_firewall(chroot_dir, firewall_config):
            success_count += 1

        total_count += 1
        ssh_config = security_config.get('ssh')
        if configure_ssh(chroot_dir, ssh_config):
            success_count += 1

        total_count += 1
        file_permissions_config = security_config.get('file_permissions')
        if configure_file_permissions(chroot_dir, file_permissions_config):
            success_count += 1
        
        print(f"Security configuration completed: {success_count}/{total_count} components configured successfully")
        return success_count == total_count
    
    except Exception as e:
        print(f"Error setting up security configuration: {str(e)}")
        return False
