#!/bin/bash

PROGNAME="$(basename $0)"

OPENCV_VERSION=4.1.0
OPENCV_FLAG=0
TFLITE_VERSION="v2.1.2"
TFLITE_FLAG=0
USER_S=$(sudo bash -c "echo $USER")
BUILD_DIR=$(pwd)
PREFIX_INSTALL="/usr/local"

usage() {
    echo "Script for install OpenCV and TensorFlow Lite"
    echo "Usage: $PROGNAME [options]"
    echo
    echo "Options:"
    echo "  -h, --help              displays text about using the script"
    echo "      --without-cv        don't install OpenCV"
    echo "      --without-tf        don't install TensorFlow Lite"
    echo "      --cv-version <v>    set OpenCV version (default: $TFLITE_VERSION)"
    echo "      --tf-version <v>    set TensorFlow Lite version"
    echo "                          (default: $OPENCV_VERSION)"
    echo "  -b, --build-dir <dir>   path to the folder where the libraries"
    echo "                          are being built (default: $BUILD_DIR)"
    echo "  -p, --prefix-install    path to the folder where the libraries"
    echo "                  <dir>   are installed (default: /usr/local)"
}

if [[ $(id -u) -ne 0 ]]; then
    echo "-- Script must be run as root"
    exit 1
fi

GETOPT_ARGS=$(getopt -o hb:p:: -l "help","without-cv","without-tf","cv-version","tf-version","build-dir","prefix-install" -n "$PROGNAME" -- "$@")
[[ $? -ne 0 ]] && exit 1
eval set -- "$GETOPT_ARGS"

while :; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --without-cv)
            shift
            OPENCV_FLAG=1
            ;;
        --without-tf)
            shift
            TFLITE_FLAG=1
            ;;
        --cv-version)
            shift
            OPENCV_VERSION="$1"
            ;;
        --tf-version)
            shift
            TFLITE_VERSION="$1"
            ;;
        -b|--build-dir)
            shift
            BUILD_DIR="$1"
            ;;
        -p|--prefix-install)
            shift
            PREFIX_INSTALL="$1"
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ $OPENCV_FLAG -eq 1 ] && [ $TFLITE_FLAG -eq 1 ]; then
    echo "-- No targets to install"
    exit 1
fi

if ! [ -d $BUILD_DIR ]; then
    echo "-- Build dir $BUILD_DIR does not exist"
    exit 1
fi

if ! [ -d $PREFIX_INSTALL ]; then
    echo "-- Install prefix $PREFIX_INSTALL does not exist"
    exit 1
fi

# Install packages for build
echo "-- Install packages for build libraries"
sudo apt-get install -y git cmake build-essential curl pkg-config python3-dev python3-numpy python3-py &> /dev/null
if [[ $? -ne 0 ]]; then 
    echo "-- Fail to install packages"
    echo "-- Please check your internet connection"
    exit 1
fi

# **************** OpenCV 4.1.0 ****************
# Check if installed 
CV_PY_VERSION="$(python -c "import cv2 ; print(cv2.__version__)" 2> /dev/null)"
ANSWER=0
if [[ "$OPENCV_VERSION" == $CV_PY_VERSION ]] && [ $OPENCV_FLAG -eq 0 ]; then
    echo "-- OpenCV "$OPENCV_VERSION" libraries already installed"
    while [[ 1 = 1 ]]; do
	read -p "-- Skip OpenCV build? (yes/no) " ANSWER
	case $ANSWER in
	   y|yes) ANSWER=1; break;;
	   n|no) ANSWER=0; break;;
	esac
    done
fi

if [ $ANSWER -eq 0 ] && [ $OPENCV_FLAG -eq 0 ]; then
    # Install packages for OpenCV
    echo "-- Install dependencies for OpenCV"
    sudo apt-get install -y \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libeigen3-dev \
        libglew-dev \
        libgtk2.0-dev \
        libgtk-3-dev \
        libjpeg-dev \
        libpng-dev \
        libpostproc-dev \
        libswscale-dev \
        libtbb-dev \
        libtiff5-dev \
        libv4l-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libxvidcore-dev \
        libx264-dev \
        zlib1g-dev &> /dev/null
    if [[ $? -ne 0 ]]; then
	echo "Fail to download dependencies for OpenCV"
	echo "-- Please check your internet connection"
	exit 1
    fi
    # Download OpenCV sources
    cd $BUILD_DIR
    echo "-- Download OpenCV sources from github.com"
    [[ -d opencv ]] && rm -rf opencv
    git clone https://github.com/opencv/opencv.git opencv &> /dev/null
    cd opencv 
    git checkout ${OPENCV_VERSION} &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "-- Fail to checkout version $OPENCV_VERSION"
        #exit 1
    fi
    cd ..
    echo "-- Download OpenCV contrib sources from github.com"
    [[ -d opencv_contrib ]] && rm -rf opencv_contrib
    git clone https://github.com/opencv/opencv_contrib.git opencv_contrib &> /dev/null
    cd opencv_contrib 
    git checkout ${OPENCV_VERSION} &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "-- Fail to checkout version $OPENCV_VERSION"
        exit 1
    fi
    cd ..
    sudo chmod 666 opencv opencv_contrib
    
    # Build OpenCV from source
    echo "-- Build OpenCV from sources"
    cd opencv
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=$PREFIX_INSTALL \
        -D WITH_LIBV4L=ON \
        -D WITH_V4L=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_GSTREAMER_0_10=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_TESTS=OFF \
        -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules .. &> /dev/null
    if [[ $? -eq 0 ]]; then
 		echo "-- CMake configuration make successfull"
    else 
        echo "-- CMake configuration make error"
        echo "-- Please check configuration before use"
	exit 1;
    fi
    make -j4 &> /dev/null
    if [[ $? -eq 0 ]]; then
	echo "-- OpenCV build successfully"
    else 
	echo "-- OpenCV build make fail"
	echo "-- Retrying the build"
	exit 1;
    fi
    # Install OpenCV to OS
    echo -en "-- Install OpenCV in OS"
    sudo make install &> /dev/null
    sudo ldconfig
    if [[ $? -eq 0 ]]; then
	echo " - done"
        echo "-- OpenCV $OPENCV_VERSION was successfull installed to ${PREFIX_INSTALL}"
    else
        echo " - fail"
	exit 1;
    fi
fi

# *************** TensorFlow Lite **************
# Check if installed 
TFL_PKG_VERSION="$(pkg-config --modversion tflite 2> /dev/null)"
ANSWER=0
if [[ "$TFLITE_VERSION" == $TFL_PKG_VERSION ]] && [ $TFLITE_FLAG -eq 0 ]; then
    echo "-- TensorFlow Lite "$OPENCV_VERSION" libraries already installed"
    while [[ 1 = 1 ]]; do
	read -p "-- Skip TensorFlow Lite build? (yes/no)" ANSWER
	case $ANSWER in
	   y|yes) ANSWER=1; break;;
	   n|no) ANSWER=0; break;;
	esac
    done
fi

if [ $ANSWER -eq 0 ] && [ $TFLITE_FLAG -eq 0 ]; then
    # Download TFLite 2.1.2
    echo "-- Download TensorFlow Lite sources from github.com"
    cd $BUILD_DIR
    [[ -d tensorflow ]] && rm -rf tensorflow
    git clone https://github.com/tensorflow/tensorflow.git tensorflow &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "-- Fail to download sources from github.com"
        echo "-- Please check your internet connection"
        exit 1
    fi
    cd tensorflow
    git checkout $TFLITE_VERSION &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "-- Fail to checkout version $TFLITE_VERSION"
        exit 1
    fi

    # Download dependencies
    echo "-- Download dependencies for TensorFlow Lite"
    ./tensorflow/lite/tools/make/download_dependencies.sh &> /dev/null
    if [[ $? -ne 0 ]]; then
	echo "-- Fail to download dependencies for TensorFlow Lite"
	echo "-- Please check your internet connection"
	exit 1
    fi
	
    # Build TFLite from sources
    echo "-- Build TensorFlow Lite from sources"
    ./tensorflow/lite/tools/make/build_lib.sh &> /dev/null
    if [[ $? -eq 0 ]]; then
	echo "-- TensorFlow Lite build successfully"
    else 
	echo "-- TensorFlow Lite build make fail"
	echo "-- Retrying the build"
	exit 1;
    fi

    # Copy TensorFlow Lite files
    echo -en "-- Install TensorFlow Lite in OS"
    LINUX_ARCH="linux_$(uname -m)"
    [[ -d $PREFIX_INSTALL/lib/ ]] || mkdir $PREFIX_INSTALL/lib
    cp tensorflow/lite/tools/make/gen/${LINUX_ARCH}/lib/libtensorflow-lite.a $PREFIX_INSTALL/lib/libtensorflow-lite.a
    [[ -d $PREFIX_INSTALL/include/ ]] || mkdir $PREFIX_INSTALL/include
    [[ -d $PREFIX_INSTALL/include/tensorflow/lite/ ]] || sudo mkdir -p $PREFIX_INSTALL/include/tensorflow/lite
    cp -ra tensorflow/lite $PREFIX_INSTALL/include/tensorflow
    if [[ $? -eq 0 ]]; then
	echo " - done"
        echo "-- TensorFlow Lite $TFLITE_VERSION was successfull installed to ${PREFIX_INSTALL}"
    else
        echo " - fail"
	exit 1;
    fi
    cd $BUILD_DIR && rm -rf tensorflow

    # Generate .pc for pkg-config
    echo "-- Generate pkg-config file for TensorFlow Lite"
    [[ -f /usr/share/pkgconfig/tflite.pc ]] || sudo touch /usr/share/pkgconfig/tflite.pc
    cat << EOF > /usr/share/pkgconfig/tflite.pc
prefix=${PREFIX_INSTALL}
exec_prefix=${prefix}
includedir=${prefix}/include
libdir=${exec_prefix}/lib

Name: tflite
Description: A set of tools for transforming and running TensorFlow models
Version: '${TFLITE_VERSION}'
Cflags: -I'${includedir}'/
Libs: -L'${libdir}' -ltensorflow-lite
EOF
fi
