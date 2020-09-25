#!/bin/bash

cd grouppy
rm -r packages/*
make package
mkdir workdir
dpkg-deb -R packages/*.deb workdir
cp workdir/Library/MobileSubstrate/DynamicLibraries/grouppy.dylib ..
rm -r workdir
cd ..