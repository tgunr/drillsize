#!/bin/sh

# debufprefs.sh
# PDFGarden
#
# Created by Dave Carlton on 10/11/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.


set -x
if [[ "$CONFIGURATION" == 'Debug Prefs' ]]; then
	if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" ]; then
		if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]; then
		    echo "Removing prefs"
		    /bin/rm "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist"
		else
		    echo "Moving prefs aside"
		    /bin/mv "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1"
		fi
	fi
elif [[ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]]; then
		echo "Old prefs still exists at $HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1"
fi

if [[ "$CONFIGURATION" != 'Release' ]]; then
	if [[ -e "${SRCROOT}/Misc/receipt" ]] ; then
		mkdir -p  "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/_MASReceipt"
		cp -f "${SRCROOT}/Misc/receipt" "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/_MASReceipt"
	fi
fi