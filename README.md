# QuickMD

QuickMD is a native macOS Quick Look extension for Markdown files. Select an `.md` or `.markdown` file in Finder and press Space to see a styled preview.

## Build

Run `./script/build_and_run.sh`. The script regenerates the Xcode project, builds the host app and embedded extension, and launches QuickMD.

The host app uses `dev.bunn.quickmd`; the embedded Quick Look extension uses `dev.bunn.quickmd.preview`.

After launching the app, enable **QuickMD Preview** in **System Settings › General › Login Items & Extensions › Quick Look**.
