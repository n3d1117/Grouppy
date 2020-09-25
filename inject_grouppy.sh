#!/bin/bash

IPA=$1

# Check input
ipa_filename=$(basename -- "$IPA")
ipa_ext="${ipa_filename##*.}"
if [[ "$ipa_ext" != ipa ]]; then
	echo "Error: input is not a valid .ipa file!"
	exit 1
fi
if [ ! -f "$IPA" ]; then
	echo "Error: input file not found"
	exit 1
fi
if [ ! -f grouppy.dylib ]; then
	echo "Error: grouppy dylib not found, extract it with: ./extract_dylib_here.sh"
	exit 1
fi
if [ ! -f optool ]; then
	echo "Error: optool not found, get it at https://github.com/alexzielenski/optool/"
	exit 1
fi

# Create tmp folder
mkdir -p tmp

# Unzip ipa
unzip -q "$IPA" -d tmp
# Get main binary name
main_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' tmp/Payload/*.app/Info.plist)
# Copy dylib to path
cp grouppy.dylib tmp/Payload/*.app/
# Inject dylib
./optool install -c load -p "@executable_path/grouppy.dylib" -t tmp/Payload/*.app/"$main_binary"

# iterate over plugins
if [ -d tmp/Payload/*.app/PlugIns ]; then
	for plugin in tmp/Payload/*.app/PlugIns/*.appex; do
		plugin_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plugin"/Info.plist)
		# Copy dylib to path
		cp grouppy.dylib "$plugin"
		# Inject dylib
		./optool install -c load -p "@executable_path/grouppy.dylib" -t "$plugin"/"$plugin_binary"
	done
fi

# Zip new ipa
original_filename=$(basename "$IPA" .ipa)
cd tmp && zip -qr ../"$original_filename"_patched.ipa Payload
# Cleanup
cd .. && rm -rf tmp
