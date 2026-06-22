TIGERBEETLE_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}
RELEASE_SUFFIX=${4:-}

if [ -z "$TIGERBEETLE_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <tigerbeetle_version> <build_version> [architecture] [release_suffix]"
    echo "Example: $0 0.16.58 1 arm64"
    echo "Example: $0 0.16.58 1 all    # Build for all architectures"
    echo "Example: $0 0.17.7 1 all 1   # Upstream release tag is 0.17.7-1"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Build the upstream release tag used in the GitHub asset URL
if [ -n "$RELEASE_SUFFIX" ]; then
    RELEASE_TAG="${TIGERBEETLE_VERSION}-${RELEASE_SUFFIX}"
else
    RELEASE_TAG="${TIGERBEETLE_VERSION}"
fi

get_tigerbeetle_release() {
    local arch=$1
    case "$arch" in
        "amd64") echo "tigerbeetle-x86_64-linux" ;;
        "arm64") echo "tigerbeetle-aarch64-linux" ;;
        *) echo "" ;;
    esac
}

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

    rm -rf "$tigerbeetle_release" || true
    rm -f "${tigerbeetle_release}.zip" || true

    if ! wget "https://github.com/tigerbeetle/tigerbeetle/releases/download/${RELEASE_TAG}/${tigerbeetle_release}.zip"; then
        echo "❌ Failed to download tigerbeetle binary for $build_arch"
        return 1
    fi

    mkdir -p "$tigerbeetle_release"
    if ! unzip -j "${tigerbeetle_release}.zip" -d "$tigerbeetle_release"; then
        echo "❌ Failed to extract tigerbeetle binary for $build_arch"
        return 1
    fi

    rm -f "${tigerbeetle_release}.zip"

    declare -a arr=("jammy" "noble" "questing")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$TIGERBEETLE_VERSION-${BUILD_VERSION}+${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "tigerbeetle-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg TIGERBEETLE_VERSION="$TIGERBEETLE_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg TIGERBEETLE_RELEASE="$tigerbeetle_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "tigerbeetle-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/tigerbeetle_$FULL_VERSION.deb" - > "./tigerbeetle_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./tigerbeetle_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    rm -rf "$tigerbeetle_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building tigerbeetle $TIGERBEETLE_VERSION-$BUILD_VERSION for all supported Ubuntu architectures..."
    echo ""
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
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
