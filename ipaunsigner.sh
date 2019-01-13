#!/bin/bash

#   Copyright (C) 2019 Danii Pashin <admin@danpashin.ru>
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.

IPA_PATH=$1;

# First we check if file path is provided, file is an ipa archive and it exists in filesystem.
if [ ! ${#IPA_PATH} -ge 1 ]; then
    echo "Usage: ./ipaunsigner.sh path_to_ipa_file";
    exit 1;
fi

if [ "${IPA_PATH##*.}" != "ipa" ]; then
    echo "Error: file is not an ipa archive.";
    exit 1;
fi

if [ ! -f "$IPA_PATH" ]; then
    echo "Error: ipa file was not found.";
    exit 1;
fi

# Then we get different information about ipa to display.
IPA_FOLDER=$(dirname $IPA_PATH);
IPA_NAME=$(basename $IPA_PATH);

echo "Processing $IPA_NAME...";

# And removing payload folder in ipa directory. With user agreement, of course.
if [ -d "$IPA_FOLDER/Payload" ]; then
    should_remove_payload="y"
    read -p "Found Payload in current directory. Want to remove? (y/n) [y] " should_remove_payload;
    
    if [ "$should_remove_payload" == "y" ]; then
        echo "[->] Removing current Payload directory";
        rm -rf "$IPA_FOLDER/Payload" > /dev/null;
    fi
fi


# After all checks we can start unsign process.
# Firstly, we have to unzip ipa.
echo "[->] Unzipping (1/5)"
/usr/bin/unzip "$IPA_PATH" -d "$IPA_FOLDER" > /dev/null;

# Removing macosx folder if it exists. macOS created it when ipa  was packagaged via system compress menu.
if [ -d "$IPA_FOLDER/__MACOSX" ]; then
    rm -rf "$IPA_FOLDER/__MACOSX" > /dev/null;
fi


# Getting .app folder name in Payload. It will be useful for us in the future.
# But this check is a bit wrong. Here we chould check if Payload contains only one .app folder to avoid corrupted ipas.
APP_FOLDER_NAME=$(ls "$IPA_FOLDER/Payload" | sort -n | head -1);
APP_FOLDER_PATH="$IPA_FOLDER/Payload/$APP_FOLDER_NAME";

# FINALLY! To correctly unsign app we have to remove all files and folders that were used for signing firstly.
# If we don't do this, codesign can generate a corrupted executable (which we we wouldn't want to see).
echo "[->] Unsigning (2/5)";
find "$APP_FOLDER_PATH" \( -name "archived-expanded-entitlements.xcent" -o -name "embedded.mobileprovision" -o -name "PkgInfo" -o -name "_CodeSignature" \) -exec rm -rf "{}" \; 2>/dev/null;

# Then we unsign all possible bundles, libraries and frameworks.
echo "[->] Unsigning (3/5)";
find "$APP_FOLDER_PATH" \( -name "*.dylib" -o -name "*.framework" -o -name "*.appex" \) -exec /usr/bin/codesign --remove-sign "{}" \;

# And finally main executable. There should be one more check if executable is really exists, but we have what we have ¯\_(ツ)_/¯
MAIN_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$APP_FOLDER_PATH/Info.plist");
if [ ${#MAIN_EXECUTABLE} -ge 1 ]; then
    echo "[->] Unsigning (4/5)";
    /usr/bin/codesign --remove-sign "$APP_FOLDER_PATH/$MAIN_EXECUTABLE";
else
    echo "Error: main executable was not found.";
    exit 1;
fi

# Last step is packaging our new unsigned app into an archive and notifing user about the result.
echo "[->] Packaging (5/5)";
cd "$IPA_FOLDER";
zip -9qr "${IPA_NAME%.*}_unsigned.ipa" "Payload";
rm -rf "$IPA_FOLDER/Payload";

# Yea! We did it!
echo "Done!";