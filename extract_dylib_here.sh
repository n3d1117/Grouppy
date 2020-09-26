#!/bin/bash

rm -f grouppy.dylib
cd grouppy
rm -rf packages/*
make package
mkdir workdir
dpkg-deb -R packages/*.deb workdir
cp workdir/Library/MobileSubstrate/DynamicLibraries/grouppy.dylib ..
rm -r workdir
cd ..