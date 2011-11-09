set -x

# Test for kill prefs file on each build
echo "BUILD_NUMBER: $BUILD_NUMBER"
echo "VERSION_NUMBER: $VERSION_NUMBER"
echo "SU_FEED: $SU_SITE/$SU_PATH/$SU_FEED" | sed -e 's?//?/?'

if [[ "$CONFIGURATION" == 'Debug New Prefs' ]]; then
	if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" ]; then
		if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]; then
		    logger "Removing prefs"
		    /bin/rm "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist"
		else
		    logger "Moving prefs aside"
		    /bin/mv "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1"
		fi
	fi
else
	# If no longer killing prefs, check for prexisting pref file and restore it
	if [[ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]]; then
		logger "restoring old prefs"
		/bin/mv "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist"
	fi
fi

### If not releasing increment build number
if [[ "$CONFIGURATION" == 'Debug' ]]; then
	/usr/bin/perl -pe 's/(BUILD_NUMBER = )(\d+)/$1.($2+1)/eg' -i "$SRCROOT/Misc/debug.xcconfig"
	BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/debug.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
	PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	PlistBuddy -c "Set :SUFeedURL http:\/\/$SU_SITE/$SU_PATH/$SU_FEED" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	
	# Naming conventions
	#NAME		= trailing file name
	#DIR		= leading path components to a folder, no trailing slash
	#PATH		= partial path component to construct URL or PATHNAME, no leading /
	#URL		= $SITE/$DIR/$NAME
	#PATHNAME	= full path to a file $DIR/$PATH/$FILE

	# Read back values to make sure they were set
	RELEASE_BUILD=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
	RELEASE_VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

	# Bases
	if [[ "" = "$SU_PATH" ]] ; then
		SITE_BASE="http://${SU_SITE}"
	else
		SITE_BASE="http://${SU_SITE}/${SU_PATH}"
	fi

	UPDATES_BASE="$SRCROOT"/updates

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


	WD=$PWD
	pushd "$BUILT_PRODUCTS_DIR"
	cp -R "$PRODUCT_NAME".app "$ARCHIVE_FILE".app
	ditto -ck --keepParent "$PRODUCT_NAME".app "$ARCHIVE_FILE".zip
	popd
fi
