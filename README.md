# Calibre File Monitor

A [KOReader](https://koreader.rocks) plugin that automatically synchronizes Calibre library metadata (`metadata.calibre`) with file operations in the built-in file manager.

## Features

- **Rename/Move books** — updates `lpath` in metadata when a book file is renamed or moved
- **Rename/Move directories** — updates `lpath` for all descendant books when a directory is renamed or moved
- **Delete books** — removes entries from metadata when books are deleted
- **Delete directories** — removes all descendant book entries when a directory is deleted

## Requirements

- KOReader with a Calibre library directory configured as the **inbox directory** (`inbox_dir` setting)
- A Calibre library containing a `metadata.calibre` file

## Installation

1. Download the latest `.zip` from [Releases](https://github.com/tachibana-shin/calibre_filemon.koplugin/releases)
2. Extract the `calibre_filemon.koplugin` folder into KOReader's `plugins/` directory:
   - **Linux:** `~/.config/koreader/plugins/`
   - **Kindle:** `/mnt/us/koreader/plugins/`
   - **Kobo:** `/mnt/onboard/.adds/koreader/plugins/`
   - **Android:** `/sdcard/koreader/plugins/`
   - **PocketBook:** `/mnt/ext1/koreader/plugins/`
3. Restart KOReader or reload plugins

## Usage

1. Open KOReader and navigate to a Calibre library directory
2. Set it as inbox: tap the top menu → **Tools** → **Calibre** → **Set inbox directory**
3. The plugin automatically activates when you rename, move, or delete files/directories inside the inbox
4. Metadata updates happen silently in the background

## Development

```bash
# Create distributable zip
make build

# Clean build artifacts
make clean

# Show current version
make version
```

Commits should follow [Conventional Commits](https://www.conventionalcommits.org/) to enable automatic versioning via semantic-release.

## License

AGPL-3.0
