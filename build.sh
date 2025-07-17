#!/bin/bash

# Simple PKI Docker Build Script
set -e

# Default values
BASE_IMAGE="debian:bookworm-slim"
TAG="pki-dev:latest"
LANGUAGES=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Help function
show_help() {
    echo "Simple PKI Docker Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --alpine         Use Alpine Linux base"
    echo "  --debian         Use Debian base (default)"
    echo "  --ubuntu         Use Ubuntu base"
    echo "  --base IMAGE     Use custom base image"
    echo "  --tag TAG        Set image tag (default: pki-dev:latest)"
    echo "  --nodejs         Install Node.js"
    echo "  --python         Install Python"
    echo "  --golang         Install Go"
    echo "  --rust           Install Rust"
    echo "  --java           Install Java"
    echo "  --all            Install all languages"
    echo "  --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --alpine --nodejs --python"
    echo "  $0 --debian --all"
    echo "  $0 --ubuntu --golang --rust --tag my-dev:v1.0"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --alpine) BASE_IMAGE="alpine:latest"; shift ;;
        --debian) BASE_IMAGE="debian:bookworm-slim"; shift ;;
        --ubuntu) BASE_IMAGE="ubuntu:22.04"; shift ;;
        --base) BASE_IMAGE="$2"; shift 2 ;;
        --tag) TAG="$2"; shift 2 ;;
        --nodejs) LANGUAGES+=("NODEJS"); shift ;;
        --python) LANGUAGES+=("PYTHON"); shift ;;
        --golang) LANGUAGES+=("GOLANG"); shift ;;
        --rust) LANGUAGES+=("RUST"); shift ;;
        --java) LANGUAGES+=("JAVA"); shift ;;
        --all) LANGUAGES=("NODEJS" "PYTHON" "GOLANG" "RUST" "JAVA"); shift ;;
        --help) show_help; exit 0 ;;
        *) print_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Validate certificates directory
if [[ ! -d "certs" ]]; then
    print_info "Creating empty certs directory"
    mkdir -p certs
fi

# Build command
BUILD_CMD="docker build -t $TAG --build-arg BASE_IMAGE=$BASE_IMAGE"

# Add language arguments
for lang in "${LANGUAGES[@]}"; do
    BUILD_CMD="$BUILD_CMD --build-arg INSTALL_$lang=true"
done

BUILD_CMD="$BUILD_CMD ."

# Show build info
print_info "Building PKI Development Environment"
print_info "Base Image: $BASE_IMAGE"
print_info "Tag: $TAG"
print_info "Languages: ${LANGUAGES[*]:-none}"
print_info "Command: $BUILD_CMD"
echo ""

# Execute build
if eval "$BUILD_CMD"; then
    print_success "Build completed successfully!"
    print_info "Image: $TAG"
    echo ""
    print_info "Usage:"
    echo "  docker run -it --rm $TAG"
    echo "  docker run -it --rm -v ./certs:/usr/local/share/ca-certificates:ro $TAG"
    echo ""
else
    print_error "Build failed!"
    exit 1
fi