#!/bin/bash
set -e

PROJECT_ROOT=$(cd "$(dirname "$0")" && pwd)
IMAGE_NAME="kioskbuilder"
IMAGE_TAG="latest"

function build_image() {
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME:$IMAGE_TAG" -f "$PROJECT_ROOT/docker/Dockerfile" "$PROJECT_ROOT"
}

function show_help() {
    echo "Usage: $0 [options] <config.yml>"
    echo ""
    echo "Options:"
    echo "  --build-only     Only build the Docker image, don't run it"
    echo "  --help           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 example.yml"
}

BUILD_ONLY=false
LOCAL=false
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            CONFIG_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$CONFIG_FILE" && "$BUILD_ONLY" == "false" ]]; then
    show_help
    exit 1
fi

if [[ -n "$CONFIG_FILE" && ! "$CONFIG_FILE" = /* ]]; then
    CONFIG_FILE="$PWD/$CONFIG_FILE"
fi

if [[ -n "$CONFIG_FILE" && ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file does not exist: $CONFIG_FILE"
    exit 1
fi

build_image

if [[ "$BUILD_ONLY" == "true" ]]; then
    echo "Docker image built successfully"
    exit 0
fi

CONFIG_DIR=$(dirname "$CONFIG_FILE")
CONFIG_FILENAME=$(basename "$CONFIG_FILE")

echo "Running KioskBuilder with config: $CONFIG_FILE"
docker run --rm -it \
    --privileged \
    -v "$CONFIG_FILE:/config.yml" \
    -v "$CONFIG_DIR:/output" \
    "$IMAGE_NAME:$IMAGE_TAG"
