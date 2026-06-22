TIGERBEETLE_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}
RELEASE_SUFFIX=${4:-}
./build_debian.sh $1 $2 $3 $4
./build_ubuntu.sh $1 $2 $3 $4
./build_src.sh $1 $2
