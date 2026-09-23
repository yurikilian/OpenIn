# OpenIn

A tiny macOS Finder extension that adds an **Open in** submenu to Finder's context menu, so you can open any folder straight in your IDE.

```
Right-click a folder ─▶ Open in ─▶ Visual Studio Code
                                   Zed
                                   IntelliJ IDEA
                                   Orca
```

- Works on selected folders, on the empty background of a Finder window (opens the current folder), and on sidebar items.
- Right-clicking a file opens its parent folder.
- Only IDEs that are actually installed show up in the menu.

## Requirements

- macOS 26 or later
- Xcode 26 or later
- An Apple Development signing certificate (a free Apple ID works — sign in under Xcode → Settings → Accounts)

## Install

```bash
git clone https://github.com/yurikilian/OpenIn.git
cd OpenIn
./install.sh
```

`install.sh` will:

1. Build the app in Release, signed with the first `Apple Development` certificate in your keychain (override with `DEVELOPMENT_TEAM=<team id> ./install.sh`).
2. Copy it to `/Applications/OpenIn.app`.
3. Register and enable the Finder extension with `pluginkit`.
4. Restart Finder.

Then right-click any folder in Finder → **Open in**.

If the menu doesn't show up, make sure the extension is enabled in **System Settings → General → Login Items & Extensions → File Providers / Finder** (or open `OpenIn.app` and click **Manage Finder Extension**).

## Adding another IDE

Add a case to the `AppTarget` enum in [`OpenInFinderExtension/FinderSync.swift`](OpenInFinderExtension/FinderSync.swift) and fill in its `name` and `bundleIdentifier`:

```swift
case cursor = 5

// in `name`
case .cursor:
    return "Cursor"

// in `bundleIdentifier`
case .cursor:
    return "com.todesktop.230313mzl4w4u92"
```

Find an app's bundle identifier with:

```bash
osascript -e 'id of app "Cursor"'
```

Run `./install.sh` again to rebuild. Installed IDEs are detected when the extension starts, so if you install a new IDE later, run `killall Finder` to pick it up.

## How it works

- `OpenInApp/` — a small SwiftUI host app. It only shows whether the extension is enabled and links to its settings.
- `OpenInFinderExtension/` — a [Finder Sync extension](https://developer.apple.com/documentation/findersync) that watches `/` and contributes the **Open in** menu. It hands the folder to the IDE with `NSWorkspace.open(_:withApplicationAt:configuration:)`.

Finder Sync extensions must be sandboxed, and a sandboxed process can't ask Launch Services to open a folder it has no access to. The extension therefore uses the `com.apple.security.temporary-exception.files.absolute-path.read-only` entitlement for `/`. That's fine for a locally built app, but it means OpenIn can't be distributed through the Mac App Store as-is.

## Uninstall

```bash
pluginkit -e ignore -i app.openin.OpenIn.FinderExtension
rm -rf /Applications/OpenIn.app
killall Finder
```

## License

[MIT](LICENSE)
