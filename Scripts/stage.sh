set -o errexit
if [[ "$CONFIGURATION" == 'Stage' ]]; then

# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

# Bases
if [[ "" = "$SU_PATH" ]] ; then
	SITE_BASE="http://${SU_SITE}"
else
	SITE_BASE="http://${SU_SITE}/${SU_PATH}"
fi

UPDATES_BASE="$SRCROOT"/updates

# Variables

# Get the build number from the debug.xcconfig and set the stage.xccofig file
# This way, we stay at a constant build number until we go back to debugging
BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/debug.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
sed -e "s/BUILD_NUMBER = .*/BUILD_NUMBER = $BUILD_NUMBER/" -i ""  "$SRCROOT/Misc/stage.xcconfig"

# Have to update the application Info.plist so it knows we are on this build
PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
PlistBuddy -c "Set :SUFeedURL $SITE_BASE/$SU_FEED" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

# Read back values to make sure they were set
RELEASE_BUILD=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
RELEASE_VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

#Paths
RELEASE_NOTES_PATH="support/releasenotes"

#Directories
RELEASE_NOTES_DIR="$UPDATES_BASE"/"$RELEASE_NOTES_PATH"
KEYCHAIN_DIR="$SRCROOT/Misc"

# construct file names
ARCHIVE_FILE=`echo "${PRODUCT_NAME}_${VERSION_NUMBER}_${RELEASE_BUILD}" | tr "-" "_"`
RELEASE_NOTES="$ARCHIVE_FILE".html

#Files
KEYCHAIN_PRIVKEY_NAME="dsa_priv.pem"
XML_UPDATE_FILE="$UPDATES_BASE"/updates.xml
XML_CONFIG_FILE="$UPDATES_BASE"/supportConfig.php

# URL's
DOWNLOAD_BASE_URL="${SITE_BASE}/archives"
RELEASENOTES_URL="${SITE_BASE}/$RELEASE_NOTES_PATH/$RELEASE_NOTES"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILE"


cat <<EOF
Prelease checklist
- Update updates.xml with new version, paste in from clip board
- Update release notes
- Update known issues
- Update URL for new version, copy next line
- Turn on local hosts for pdfgarden.com
- Publish site
- Verify site
- Change build to release
- Verify not using local hosts
rsync -auv $UPDATES_BASE/ polymicrosystems.com:sites/staging/pdfgarden.com/updates/

EOF

WD=$PWD
pushd "$BUILT_PRODUCTS_DIR"
rm -f "$PRODUCT_NAME"*.zip
ditto -ck --keepParent "$PRODUCT_NAME".app "$ARCHIVE_FILE".zip

#cp "$PRODUCT_NAME".zip "$ARCHIVE_FILE"
mv "$ARCHIVE_FILE".zip "$UPDATES_BASE"/archives/

# see if release notes file for this release already exists, may be 2nd or more build so only do it once
RELEASE_NOTES_PATHNAME="$RELEASE_NOTES_DIR/$RELEASE_NOTES"
if [[ ! -e "$RELEASE_NOTES_PATHNAME" ]] ; then
	echo "Creating $RELEASE_NOTES_PATHNAME"

cat >"$RELEASE_NOTES_PATHNAME" <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 TRANSITIONAL//EN">
<html>

    <head>
        <title>Version $RELEASE_VERSION Build $RELEASE_BUILD</title>
        <link href="../css/simplelist.css" type="text/css" rel="stylesheet" media="all">
    </head>
    <body>
        <p class="p1" align="center">$PRODUCT_NAME Version $RELEASE_VERSION Build $RELEASE_BUILD </p>
        <ul class="ul1">
            <li class="li1">Item1</li>
        </ul>
    </body>
</html>
EOF
fi

if [[ "$CONFIGURATION" != 'Debug' ]] ; then
	FEEDER="PDFGarden"
else
	FEEDER="PDFGardenLocal"
fi
	
cat <<EOF
tell application "Feeder"
	activate
    set theFeed to folder item "$FEEDER" of root folder
    set feedVersion to "${VERSION_NUMBER}"
    set feedShortVersion to "${BUILD_NUMBER}"
    set feedTitle to "PDFGarden_${VERSION_NUMBER}_${BUILD_NUMBER}"
    set feedFile to POSIX file "${UPDATES_BASE}/archives/${ARCHIVE_FILE}.zip"
	set feedNotes to "${RELEASENOTES_URL}"
    make new feed item at theFeed with properties {feed:theFeed, sparkle short version:feedVersion, sparkle version:feedShortVersion, sparkle release notes:feedNotes, enclosure upload file:feedFile, item title:feedTitle} 
	set latest to number of feed items of theFeed
end tell
EOF

cat | osascript <<EOF
tell application "Feeder"
	activate
    set theFeed to folder item "$FEEDER" of root folder
    set feedVersion to "${VERSION_NUMBER}"
    set feedShortVersion to "${BUILD_NUMBER}"
    set feedTitle to "PDFGarden_${VERSION_NUMBER}_${BUILD_NUMBER}"
    set feedFile to POSIX file "${UPDATES_BASE}/archives/${ARCHIVE_FILE}.zip"
	set feedNotes to "${RELEASENOTES_URL}"
    make new feed item at theFeed with properties {feed:theFeed, sparkle short version:feedVersion, sparkle version:feedShortVersion, sparkle release notes:feedNotes, enclosure upload file:feedFile, item title:feedTitle} 
	set latest to number of feed items of theFeed
end tell
EOF

bbedit "$RELEASE_NOTES_PATHNAME" 

#sed -e 's/http:\/\/updates.pdfgarden.com\//http:\/\/staging.pdfgarden.com\/updates\//' -i .bak $XML_UPDATE_FILE $XML_CONFIG_FILE
#rsync -auv $UPDATES_BASE/ polymicrosystems.com:sites/staging/pdfgarden.com/updates/

fi
