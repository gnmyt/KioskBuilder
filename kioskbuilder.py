#!/usr/bin/env python3
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def parse_arguments():
    parser = argparse.ArgumentParser(description="KioskBuilder - Build custom Linux kiosk distributions")
    parser.add_argument("-c", "--config", required=True, help="Path to the configuration YAML file")
    parser.add_argument("-o", "--output", default=os.getcwd(),
                        help="Directory to save the ISO image (default: current directory)")
    parser.add_argument("--temp-dir",
                        help="Directory to use for temporary build files (default: system temp directory)")
    parser.add_argument("--no-cleanup", action="store_true",
                        help="Don't clean up temporary files after build (for debugging)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
    return parser.parse_args()


def main():
    args = parse_arguments()

    from src.python.main import KioskBuilder

    if not os.path.exists(args.config):
        print(f"Error: Config file not found: {args.config}", file=sys.stderr)
        sys.exit(1)

    output_dir = os.path.abspath(args.output)
    if not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir)
        except OSError as e:
            print(f"Error: Cannot create output directory: {e}", file=sys.stderr)
            sys.exit(1)
    elif not os.access(output_dir, os.W_OK):
        print(f"Error: Output directory is not writable: {output_dir}", file=sys.stderr)
        sys.exit(1)

    builder = KioskBuilder(args.config, output_dir)
    success = builder.build()

    if success:
        print("Build completed successfully!")
        sys.exit(0)
    else:
        print("Build failed!", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
