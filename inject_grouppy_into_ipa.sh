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
if [ ! -f insert_dylib ]; then
	echo "Error: insert_dylib not found, get it at https://github.com/Tyilo/insert_dylib"
	exit 1
fi
if [ ! -d CydiaSubstrate.framework ]; then
	echo "Error: CydiaSubstrate Framework not found, get it at http://apt.saurik.com/debs/"
	exit 1
fi

SUBSTRATE_PATH="/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"
SUBSTRATE_NEW_PATH="@rpath/CydiaSubstrate.framework/CydiaSubstrate"

# Create tmp folder
mkdir -p tmp

# Unzip ipa
unzip -q "$IPA" -d tmp
# Get main binary name
main_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' tmp/Payload/*.app/Info.plist)
# Copy substrate and dylib to path
cd tmp/Payload/*.app/
mkdir -p Frameworks
cp -rn ../../../CydiaSubstrate.framework Frameworks
cp ../../../grouppy.dylib Frameworks
# Add rpath
install_name_tool -add_rpath "@executable_path/Frameworks" "$main_binary"
# Change CydiaSubstrate path
install_name_tool -change "$SUBSTRATE_PATH" "$SUBSTRATE_NEW_PATH" Frameworks/grouppy.dylib
# Inject dylib
../../../insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$main_binary"
if [[ $? != 0 ]]; then
	echo "Failed to inject dylib into $main_binary"
	exit 1
fi

# Iterate over plugins
if [ -d PlugIns ]; then
	for plugin in PlugIns/*.appex; do
		plugin_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plugin"/Info.plist)
		# Copy substrate and dylib to path
		mkdir -p "$plugin"/Frameworks
		cp -rn ../../../CydiaSubstrate.framework "$plugin"/Frameworks
		cp ../../../grouppy.dylib "$plugin"/Frameworks
		# Add rpath
		install_name_tool -add_rpath "@executable_path/Frameworks" "$plugin"/"$plugin_binary"
		# Change path
		install_name_tool -change "$SUBSTRATE_PATH" "$SUBSTRATE_NEW_PATH" "$plugin"/Frameworks/grouppy.dylib
		# Inject dylib
		../../../insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$plugin"/"$plugin_binary"
		if [[ $? != 0 ]]; then
			echo "Failed to inject dylib into $plugin_binary"
			exit 1
		fi
	done
fi

# Zip new ipa
original_filename=$(basename "$IPA" .ipa)
cd ../.. && zip -qr ../"$original_filename"_patched.ipa Payload
# Cleanup
cd .. && rm -rf tmp
