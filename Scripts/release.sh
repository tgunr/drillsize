set -o errexit
set -x
if [[ "$CONFIGURATION" == 'Release' ]]; then
# Variables

# Get the build number from the debug.xcconfig and set the release.xccofig file
# This way, we stay at a constant build number until we go back to debugging
BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/debug.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
sed -e "s/BUILD_NUMBER = .*/BUILD_NUMBER = $BUILD_NUMBER/" -i ""  "$SRCROOT/Misc/release.xcconfig"

# Have to update the application Info.plist so it knows we are on this build
PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
#PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
#PlistBuddy -c "Set :SUFeedURL $SU_SITE/$SU_FEED_URL" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

# Read back values to make sure they were set
RELEASE_BUILD=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
RELEASE_VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

# Directories
UPDATES_BASE="$SRCROOT"/updates

# construct file names
ARCHIVE_FILE=`echo "${PRODUCT_NAME}_${VERSION_NUMBER}_${RELEASE_BUILD}" | tr "-" "_"`
RELEASE_NOTES="$ARCHIVE_FILE".html

WD=$PWD
pushd "$BUILT_PRODUCTS_DIR"
rm -f "$PRODUCT_NAME"*.zip
ditto -ck --keepParent "$PRODUCT_NAME.app" "$ARCHIVE_FILE".zip
#cp "$PRODUCT_NAME".zip "$ARCHIVE_FILE"
mv "$ARCHIVE_FILE".zip "$UPDATES_BASE"/archives/
popd

fi