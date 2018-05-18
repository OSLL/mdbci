# MDBCI packaging as AppImage

This directory contains a set of scripts that allow to package MDBCI tool as the [AppImage](https://appimage.org/) executable.

In order to package the AppImage you should install [Docker](https://www.docker.com/) and run the `build.sh` passing the version number to apply. The version is passed as the first parameter to the script. The script packages current state of MDBCI code base into the AppImage. The resulting application can be found in `build/out` subdirectory.

The purpose of the files in the directory is the following:

* `build.sh` controlls the whole build process.
* `mdbci.desktop` is required to build AppImage, it specifies the name of the executable and the name of the icon to use in the AppImage.
* `mdbci.png` is the icon that will be used in the AppImage.
* `mdbci.sh` is script that runs during the packaging procedure.
* `ruby.appimage` is the generalized set of scripts to create AppImage for Ruby application on the local host and inside the Docker image.
