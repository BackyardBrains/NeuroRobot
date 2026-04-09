#!/bin/sh
# Re-sign libtensorflowlite_c-mac.dylib and other problematic libs
# This script should be run as a "Run Script" build phase in Xcode, after "Embed Frameworks".

echo "Searching for libs to re-sign in ${CODESIGNING_FOLDER_PATH}..."

# Find and resign libtensorflowlite_c-mac.dylib
find "${CODESIGNING_FOLDER_PATH}" -name "libtensorflowlite_c-mac.dylib" -print0 | while IFS= read -r -d '' file; do
    echo "Stripping debugging symbols: ${file}"
    strip -S "${file}"
    echo "Re-signing: ${file}"
    # --force: overwrite existing signature
    # --options runtime: enable Hardened Runtime (required for notarization)
    # --verbose: show details
    # --sign: use the identity Xcode is currently using
    codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --options runtime "${file}"
done

echo "Re-signing complete."
