```
 ██╗  ██╗ ██████╗ ██████╗██╗     ███████╗ █████╗ ███╗   ██╗
 ╚██╗██╔╝██╔════╝██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║
  ╚███╔╝ ██║     ██║     ██║     █████╗  ███████║██╔██╗ ██║
  ██╔██╗ ██║     ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║
 ██╔╝ ██╗╚██████╗╚██████╗███████╗███████╗██║  ██║██║ ╚████║
 ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

A lightweight Bash CLI tool to manage and clean Xcode's DerivedData folder — free up gigabytes of build cache in seconds right from your terminal.

### Why xcclean?

Xcode's DerivedData folder silently accumulates build artifacts, index stores, and module caches. On an active machine it easily exceeds **10+ GB**. The options without `xcclean`:

- **Xcode UI** — buried under *Settings → Locations → DerivedData → arrow button*. Slow and clunky.
- `rm -rf ~/Library/Developer/Xcode/DerivedData` — works, but one typo and you're having a bad day.
- **Third-party GUI apps** — overkill for what is essentially a folder delete.

`xcclean` gives you a fast, safe, readable CLI with partial-name matching, confirmation prompts, and auto-detection of custom DerivedData paths.

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Mohamed-Khaterr/xcclean/main/install.sh | bash
```

Verify it works:

```bash
xcclean help
```

## Usage

```bash
xcclean                    # List all projects and total size
xcclean ls                 # List all DerivedData projects
xcclean size               # Show total disk usage
xcclean clean              # Clean ALL DerivedData (prompts for confirmation)
xcclean clean <name>       # Clean a specific project by partial name
xcclean path               # Print the DerivedData path
xcclean help               # Show usage
```

### Examples

**List all projects**

```bash
$ xcclean ls

DerivedData projects:

  Project                                            Size       Modified
  ──────────────────────────────────────────────── ──────────  ─────────────
  EBCMobile-abcxyz123                               2.4 GB     2025-06-10 09:12
  PaymentSDK-defuvw456                              1.1 GB     2025-06-09 14:45
  CoreUI-ghijkl789                                  640 MB     2025-06-08 11:30
  NetworkLayer-mnopqr012                            320 MB     2025-06-06 17:22
  TestHarness-stuvwx345                             180 MB     2025-05-28 09:05

  Total: 4.64 GB  (5 projects)
```

**Clean a specific project**

```bash
$ xcclean clean EBCMobile

⚠  Removing: EBCMobile-abcxyz123 (2.4 GB)
   Continue? [y/N]: y

✓  Cleaned 2.4 GB from EBCMobile-abcxyz123
```

**Clean everything**

```bash
$ xcclean clean

⚠  This will delete ALL DerivedData (4.64 GB).
   Xcode will rebuild indexes on next open.

   Continue? [y/N]: y

✓  Cleaned 4.64 GB across 5 projects.
```

**Check disk usage**

```bash
$ xcclean size

DerivedData disk usage:
  ~/Library/Developer/Xcode/DerivedData
  4.64 GB
```

## Multiple Xcode Versions

All Xcode versions share the same DerivedData path by default:

```bash
~/Library/Developer/Xcode/DerivedData
```

If you've set a custom path under **Xcode → Settings → Locations → DerivedData**, `xcclean` auto-detects it by reading Xcode's preferences plist:

```bash
defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation
```

Falls back to the default path if no custom value is found.

> **Tip:** To keep Xcode 15 and Xcode 16 builds fully isolated, set a different DerivedData path in each Xcode's settings. Then use the `DD` env variable to target either one:
>
> ```bash
> DD=~/DerivedData-Xcode15 xcclean ls
> DD=~/DerivedData-Xcode16 xcclean clean EBCMobile
> ```

## Requirements

- macOS (Bash or Zsh)
- Xcode installed (obviously)

No third-party dependencies.