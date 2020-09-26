# Grouppy
An iOS patch to make Mach-O binaries use the real application groups entitlements evaluated at runtime.

## Requirements
* `insert_dylib` binary placed in root folder, you can find it [here](https://github.com/Tyilo/insert_dylib)
* `theos` installed on your machine, [see installation guide here](https://github.com/theos/theos/wiki/Installation)
* A decrypted iOS application you wish to patch

## Usage
* Extract the `grouppy.dylib` file from theos tweak in `grouppy` folder, either by compiling it manually, by executing `./extract_dylib_here.sh` script, or by downloading a precompiled version from the [releases](https://github.com/n3d1117/Grouppy/releases/latest) page.
* Copy `grouppy.dylib` and `CydiaSubstrate.framework` to the `Frameworks` folder of the app (in `Payload/XXX.app/`)
* Add the `Frameworks` folder to the runtime search path of the binary file:
```bash
install_name_tool -add_rpath "@executable_path/Frameworks" PATH_TO_BINARY_FILE
```
* Point the `CydiaSubstrate` path linked in `grouppy.dylib` to the `Frameworks` folder:
```bash
install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate @rpath/CydiaSubstrate.framework/CydiaSubstrate Frameworks/grouppy.dylib
```
* Finally, run the following command to inject the library into the Mach-O binary you wish to patch:
```bash
./insert_dylib --inplace --all-yes "@executable_path/grouppy.dylib" PATH_TO_BINARY_FILE
```
* Done!

## Work with .ipa files or .app folders
If your app contains plugins, you may want to inject Grouppy into them as well, otherwise they won't be able to communicate with the main app because of the different application groups. Another script is included, `inject_grouppy.sh`, to demonstrate injecting Grouppy into all Mach-O binaries of a given `.ipa` file or `.app` folder (i.e. app binary and each plugin in the `PlugIns` folder). NOTE: the script will overwrite the original `ipa` file or `.app` folder.

Usage: `./inject_grouppy.sh PATH_TO_IPA_FILE_OR_APP_FOLDER`.

## License
MIT License. See [LICENSE](LICENSE) file for further information.
