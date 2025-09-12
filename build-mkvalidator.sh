#!/bin/bash
#save this file real path
SCRIPT=$(readlink -f "$0")
#save this file real path directory
SCRIPTPATH=$(dirname "$SCRIPT")
git clone https://github.com/Matroska-Org/foundation-source.git "$SCRIPTPATH/Sources/foundation-source"
cmake -S "$SCRIPTPATH/Sources/foundation-source" -B "$SCRIPTPATH/Build/foundation-source"
cmake --build "$SCRIPTPATH/Build/foundation-source" --config Release
cp "$SCRIPTPATH/Build/foundation-source/mkvalidator/mkvalidator" "$SCRIPTPATH/mkvalidator"
