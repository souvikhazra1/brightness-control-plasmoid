#!/bin/bash

if ! [ -a build ] ; then
    mkdir build
fi
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release  .. -Wno-dev
make -j$(nproc)
sudo make install
