#!/bin/bash
set -e
set -o pipefail

Major_version=$(python3 -c"import sys; print(sys.version_info.major)")
Minor_version=$(python3 -c"import sys; print(sys.version_info.minor)")
if [[ -z "$Major_version" ]]
then
    echo "No Python!"
    exit 1
else
    if [[ $Major_version -lt 3 ]] || [[ $Minor_version -lt 7 ]]; then
    echo "This project requires python 3.7 or newer"
    exit 1
    fi
fi

echo "Git Clone Protobuf"
FOLDER=protobuf
if [ ! -d "$FOLDER" ] ; then
    git clone https://github.com/protocolbuffers/protobuf
    cd protobuf/
else
    cd "$FOLDER"
    git checkout main
    git pull https://github.com/protocolbuffers/protobuf
fi

git submodule update --init --recursive

echo "Checkout your desired branch"

git checkout v21.4

echo "Build and install C++ Code"

apt-get install autoconf automake libtool curl make g++ unzip -y
./autogen.sh
./configure
make
make check || Result=$?
if [[ Result -ne 0 ]] ; then
     echo " make check failed, you can install but some features will not work properly.Proceed at your own risk. Type 1 for Yes & 2 for No"
     read x
     if [[ $x -eq "2" ]] ; then
        exit 1
     fi
fi
make install
ldconfig

echo "Check protc version"
protoc --version

echo "Build and Test pure python"
cd python/
python3 setup.py build
pip3 install tzdata
python3 setup.py test

echo "Build,test and use the C++ implementation"
python3 setup.py build --cpp_implementation
python3 setup.py test --cpp_implementation

apt-get install maven -y
echo "Build and Test java"
cd ../java/
mvn install
mvn test
