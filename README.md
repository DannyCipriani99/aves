# Aves (fork with folder include / exclude)

A personal fork of [Aves](https://github.com/deckerst/aves), the Android gallery and metadata explorer made by Thibault Deckers with Flutter.

This fork adds control over **which folders show up in the gallery**, including **hidden folders**. Everything else works as in the original app.

## What was added

All options are in **Settings → Privacy → Scan folders**.

- **Folders to include**: pick folders that are scanned directly on the file system, even when the system media index ignores them (for example folders containing a `.nomedia` file, or hidden folders).
- **Folders to exclude**: pick folders whose items are left out of the gallery.
- **Include works as an exception to exclude**: the most specific rule wins. Excluding `/storage/emulated/0` and including `/storage/emulated/0/Ex` shows only what is in `Ex`.
- **Show hidden folders**: a switch. When off, folders starting with a dot (`.`) are hidden everywhere, including in the Albums tab. When on, they are shown.
- **Built-in folder picker**: browse any folder (including `Download` and hidden ones) instead of the system file picker.
- **Rescan button**: refreshes the included folders, adding new files and dropping deleted ones.
- **Edit items from included folders**: delete, move and rename work on items found by the folder scan.
- Changes to the rules apply immediately, and nothing is deleted from the app database, so removing a rule brings the items back.
- Interface texts were added in English and Arabic.

## Required permission

Reading and editing hidden or `.nomedia` folders needs **All files access**. The app opens the right settings page the first time you add a folder. Because of this permission, this fork is meant to be installed manually, not from an app store.

## Get the app

Download the APK from the [Releases](../../releases) page of this repository. For most phones, choose the file named `arm64-v8a`.

## Build it yourself

Go to the **Actions** tab, choose **Build APK**, and press **Run workflow** on the `develop` branch. When the build finishes, the APK files are published in [Releases](../../releases). The APKs are signed with a throwaway key, so a new build may need an uninstall of the previous one before installing.

To build locally instead:

```
scripts/apply_flavor_libre.sh
./flutterw build apk -t lib/main_libre.dart --flavor libre --split-per-abi
```

## Credits and license

Aves is created by [Thibault Deckers](https://github.com/deckerst). Original project: <https://github.com/deckerst/aves>. This fork keeps the original [BSD 3-Clause license](LICENSE).
