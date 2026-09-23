# TypeX Keyboard Extension

This folder contains the native iOS Custom Keyboard Extension source for TypeX.

## What can be done now

The extension source can be stored in GitHub now. It renders the TypeX keyboard configuration, inserts text through the iOS text document proxy, supports special actions, and has basic swipe outputs.

## What still requires a Mac

A GitHub repository cannot itself turn Swift source into a signed iOS keyboard extension. Apple normally requires Xcode on macOS to create the Custom Keyboard Extension target, configure signing, enable the App Group entitlement, and install the extension on an iPhone.

## Later Xcode setup

1. Open the TypeX project in Xcode.
2. Add Target -> iOS -> Application Extension -> Custom Keyboard Extension.
3. Name it TypeXKeyboard.
4. Add the three Swift files in this folder to that target.
5. Enable the same App Group on the main app and extension: group.com.typex.shared
6. Build and install on an iPhone.
7. On iPhone: Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard -> TypeX.

## Configuration sync

The extension reads JSON from the App Group using the key TypeX.currentKeyboard.

The current designer saves to normal app UserDefaults. The next app-side change should also write the encoded keyboard JSON to UserDefaults(suiteName: "group.com.typex.shared"). That cannot be fully enabled until the App Group entitlement exists in the Xcode project.

## Current extension features

- Configurable rows and keys
- Key sizing and appearance
- Text insertion
- Backspace, space, return, shift, tab, dismiss, and next-keyboard actions
- Double-space period
- Basic swipe outputs
- QWERTY fallback when no configuration is available

