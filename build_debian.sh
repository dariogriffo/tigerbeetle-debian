TIGERBEETLE_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$TIGERBEETLE_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <tigerbeetle_version> <build_version> [architecture]"
    echo "Example: $0 0.16.58 1 arm64"
    echo "Example: $0 0.16.58 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Function to map Debian architecture to tigerbeetle release name
get_tigerbeetle_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "tigerbeetle-x86_64-linux"
            ;;
        "arm64")
            echo "tigerbeetle-aarch64-linux"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local tigerbeetle_release

    tigerbeetle_release=$(get_tigerbeetle_release "$build_arch")
    if [ -z "$tigerbeetle_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using $tigerbeetle_release"

    # Clean up any previous builds for this architecture
    rm -rf "$tigerbeetle_release" || true
    rm -f "${tigerbeetle_release}.zip" || true

    # Download and extract tigerbeetle binary for this architecture
    if ! wget "https://github.com/tigerbeetle/tigerbeetle/releases/download/${TIGERBEETLE_VERSION}/${tigerbeetle_release}.zip"; then
        echo "❌ Failed to download tigerbeetle binary for $build_arch"
        return 1
    fi

    # Create directory and extract zip file
    mkdir -p "$tigerbeetle_release"
    if ! unzip -j "${tigerbeetle_release}.zip" -d "$tigerbeetle_release"; then
        echo "❌ Failed to extract tigerbeetle binary for $build_arch"
        return 1
    fi

    rm -f "${tigerbeetle_release}.zip"

    # Build packages for all Debian distributions
    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$TIGERBEETLE_VERSION-${BUILD_VERSION}+${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "tigerbeetle-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg TIGERBEETLE_VERSION="$TIGERBEETLE_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg TIGERBEETLE_RELEASE="$tigerbeetle_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "tigerbeetle-$dist-$build_arch")"
        if ! docker cp "$id:/tigerbeetle_$FULL_VERSION.deb" - > "./tigerbeetle_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./tigerbeetle_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$tigerbeetle_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building tigerbeetle $TIGERBEETLE_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la tigerbeetle_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi