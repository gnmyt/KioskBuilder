#!/usr/bin/env python3
import os
import sys
import yaml
import shutil
import tempfile
import time

from . import validate_config
from . import base_system
from . import users
from . import software
from . import ui
from . import scripts
from . import build_iso
from . import system_config
from . import security


class KioskBuilder:
    def __init__(self, config_path, output_dir):
        self.config_path = os.path.abspath(config_path)
        self.output_dir = os.path.abspath(output_dir)
        self.build_dir = None
        self.chroot_dir = None
        self.config = None

    def load_and_validate(self):
        with open(self.config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        validate_config.validate_config(self.config)
        return True

    def setup_build_environment(self):
        self.build_dir = tempfile.mkdtemp(prefix="kioskbuilder_")
        self.chroot_dir = os.path.join(self.build_dir, "chroot")

        print(f"Build directory: {self.build_dir}")
        print(f"Chroot directory: {self.chroot_dir}")

        os.makedirs(self.output_dir, exist_ok=True)

        os.makedirs(os.path.join(self.build_dir, "configs"), exist_ok=True)

    def cleanup(self):
        if self.build_dir and os.path.exists(self.build_dir):
            print(f"Cleaning up build directory: {self.build_dir}")
            shutil.rmtree(self.build_dir)

    def build(self):
        try:
            self.load_and_validate()

            self.setup_build_environment()

            print("Setting up base system...")
            os.makedirs(self.chroot_dir, exist_ok=True)
            base_system.setup_base_system(self.build_dir)
            
            print("Configuring system settings...")
            system_config.setup_system_config(self.chroot_dir, self.config.get('system_config', {}))

            print("Running pre-install scripts...")
            scripts.execute_scripts(self.chroot_dir, self.config.get('scripts', {}), "pre_install")

            print("Configuring software...")
            software.setup_software(self.chroot_dir, self.config.get('software', {}))

            print("Configuring users...")
            users.setup_users(self.chroot_dir, self.config.get("users", []))

            print("Configuring UI...")
            ui.setup_ui(self.chroot_dir, self.config.get('ui', {}))

            print("Running post-install scripts...")
            scripts.execute_scripts(self.chroot_dir, self.config.get('scripts', {}), "post_install")

            print("Configuring security settings...")
            security.setup_security(self.chroot_dir, self.config.get('security', {}))

            print("Configuring startup scripts...")
            scripts.execute_scripts(self.chroot_dir, self.config.get('scripts', {}), "startup", execute=False)

            print("Building ISO...")
            system_name = self.config.get('system_name', 'kiosk')
            build_iso.build_iso(self.build_dir, self.config, self.output_dir)

            print(f"ISO built and saved to: {self.output_dir}/{system_name}-{time.strftime('%Y%m%d')}.iso")
            return True

        except Exception as e:
            print(f"Error building kiosk image: {e}", file=sys.stderr)
            return False

        finally:
            self.cleanup()
