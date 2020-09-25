# Grouppy
An iOS patch to make Mach-O binaries evaluate security application groups at runtime.

## Requirements
* `optool` binary placed in root folder, you can download it [here](https://github.com/alexzielenski/optool/releases)
* `theos` installed on your machine, see guide [here](https://github.com/theos/theos/wiki/Installation)

## Usage
* Extract the `dylib` file from theos tweak, either by compiling it manually, by executing `./extract_dylib_here.sh` script, or by downloading a precompiled version from the [releases](https://github.com/n3d1117/Grouppy/releases/latest) page.
* Run the following command on the Mach-O binary you wish to patch:
```
./optool install -c load -p "@executable_path/grouppy.dylib" -t PATH_TO_BINARY_FILE
```
* Done!

## IPA Files
Another script is included, `inject_grouppy.sh`, to demonstrate injecting Grouppy into all Mach-O binaries given a `.ipa` file.

Usage: `./inject_grouppy.sh PATH_TO_IPA_FILE`. A new patched `ipa` file will be generated, without overwriting the original one.

## License
MIT License. See [LICENSE](LICENSE) file for further information.
