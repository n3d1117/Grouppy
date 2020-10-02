#!/bin/bash

function realpath() {
  echo $(
    cd $(dirname $1)
    pwd
  )/$(basename $1)
}

IPA=$1
IPA_FULLPATH=$(realpath $IPA)
CURRENT_DIR=$(pwd)

# Check input
ipa_filename=$(basename -- "$IPA")
ipa_ext="${ipa_filename##*.}"
if [[ "$ipa_ext" != ipa ]] && [[ "$ipa_ext" != app ]]; then
  echo "Error: input is not a valid .ipa file or .app folder!"
  exit 1
fi

IS_IPA=true
if [[ "$ipa_ext" == app ]]; then
  IS_IPA=false
fi

if [ "$IS_IPA" = true ]; then
  if [ ! -f "$IPA" ]; then
    echo "Error: input ipa file not found"
    exit 1
  fi
else
  if [ ! -d "$IPA" ]; then
    echo "Error: input .app directory not found"
    exit 1
  fi
fi

if [ ! -f $CURRENT_DIR/grouppy.dylib ]; then
  echo "Error: grouppy dylib not found, extract it with: ./extract_dylib_here.sh"
  exit 1
fi
if [ ! -f $CURRENT_DIR/insert_dylib ]; then
  echo "Error: insert_dylib not found, get it at https://github.com/Tyilo/insert_dylib"
  exit 1
fi
if [ ! -d $CURRENT_DIR/CydiaSubstrate.framework ]; then
  echo "Error: CydiaSubstrate Framework not found, get it at http://apt.saurik.com/debs/"
  exit 1
fi

SUBSTRATE_PATH="/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"
SUBSTRATE_NEW_PATH="@rpath/CydiaSubstrate.framework/CydiaSubstrate"

if [ "$IS_IPA" = true ]; then
  # Create tmp folder
TMP=/tmp/$(openssl rand -base64 8)
mkdir -p $TMP
  # Unzip ipa
  unzip -q "$IPA" -d $TMP
else
  INPLACE_EDIT=1
  TMP=$IPA_FULLPATH
fi

# Get main binary name, copy substrate and dylib to path
if [ "$IS_IPA" = true ]; then
  main_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' $TMP/Payload/*.app/Info.plist)
  mkdir -p $TMP/Payload/*.app/Frameworks
  cp -rn $CURRENT_DIR/CydiaSubstrate.framework $TMP/Payload/*.app/Frameworks
  cp $CURRENT_DIR/grouppy.dylib $TMP/Payload/*.app/Frameworks
  cd $TMP/Payload/*.app/
else
  main_binary=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' $IPA/Info.plist)
  mkdir -p $IPA/Frameworks
  cp -rn $CURRENT_DIR/CydiaSubstrate.framework $IPA/Frameworks
  cp $CURRENT_DIR/grouppy.dylib $IPA/Frameworks
  cd $IPA
fi
# Add rpath
install_name_tool -add_rpath "@executable_path/Frameworks" "$main_binary"
# Change CydiaSubstrate path
install_name_tool -change "$SUBSTRATE_PATH" "$SUBSTRATE_NEW_PATH" Frameworks/grouppy.dylib
# Inject dylib
if [ "$IS_IPA" = true ]; then
  $CURRENT_DIR/insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$main_binary"
else
  $CURRENT_DIR/insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$main_binary"
fi
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
    if [ "$IS_IPA" = true ]; then
      cp -rn $CURRENT_DIR/CydiaSubstrate.framework "$plugin"/Frameworks
      cp $CURRENT_DIR/grouppy.dylib "$plugin"/Frameworks
    else
      cp -rn $CURRENT_DIR/CydiaSubstrate.framework "$plugin"/Frameworks
      cp $CURRENT_DIR/grouppy.dylib "$plugin"/Frameworks
    fi
    # Add rpath
    install_name_tool -add_rpath "@executable_path/Frameworks" "$plugin"/"$plugin_binary"
    # Change path
    install_name_tool -change "$SUBSTRATE_PATH" "$SUBSTRATE_NEW_PATH" "$plugin"/Frameworks/grouppy.dylib
    # Inject dylib
    if [ "$IS_IPA" = true ]; then
      $CURRENT_DIR/insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$plugin"/"$plugin_binary"
    else
      $CURRENT_DIR/insert_dylib --inplace --all-yes "@rpath/grouppy.dylib" "$plugin"/"$plugin_binary"
    fi
    if [[ $? != 0 ]]; then
      echo "Failed to inject dylib into $plugin_binary"
      exit 1
    fi
  done
fi

if [ "$IS_IPA" = true ]; then
  # Zip and overwrite ipa
  cd ../.. && zip -qrFS $IPA_FULLPATH Payload
  # Cleanup
  cd .. && rm -rf $TMP
else
  echo "not moving app as working inplace"
  # Move .app
  #cd .. && mv *.app $IPA_FULLPATH
  #do nothing
fi
