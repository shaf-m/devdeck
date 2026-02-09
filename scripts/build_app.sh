APP_NAME="DevDeck"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

# Kill existing instance to ensure update
echo "Killing existing DevDeck instances..."
pkill -f "DevDeck" || true
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating App Bundle Structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying Executable..."
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/"

echo "Copying Info.plist..."
cp "Sources/DevDeck/Resources/Info.plist" "${CONTENTS_DIR}/"

echo "Copying Resources..."
# Process resources manually if needed, or if SPM handles it?
# Provide copy of default_profiles.json if not embedded
# SPM puts resources in a bundle inside the executable usually, or alongside.
# For executable targets with resources, a .bundle is often created.
# Let's check where SPM put it.
if [ -d "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -r "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle" "${RESOURCES_DIR}/"
fi

echo "Signing App..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Done! App built at ./${APP_BUNDLE}"
