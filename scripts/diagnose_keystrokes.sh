#!/bin/bash

echo "Diagnostic: Testing AppleScript Keystrokes..."

# 1. Test Spotlight (Cmd+Space)
echo "Testing Spotlight (Cmd+Space)..."
osascript -e 'tell application "System Events" to key code 49 using {command down}'
echo "Did Spotlight appear? (Press Enter to continue)"
read

# 2. Test Ctrl+Left (Space Left)
echo "Testing Space Left (Ctrl+Left)..."
osascript -e 'tell application "System Events" to key code 123 using {control down}'
echo "Did the space switch? (Press Enter to continue)"
read

# 3. Test Ctrl+Right (Space Right)
echo "Testing Space Right (Ctrl+Right)..."
osascript -e 'tell application "System Events" to key code 124 using {control down}'
echo "Did the space switch? (Press Enter to continue)"
read

echo "Diagnostic complete."
