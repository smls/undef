Nano Syntax Highlighting
========================

These are some syntax highlighter definitions that I made for the GNU nano editor:

- `conf.nanorc` — for **system configuration files** of all kinds. (Everything from /etc/passwd files to Apache server configs and KDE settings will look reasonably pretty with this.)
- `mk.nanorc` — for **GNU makefiles**.
- `PKGBUILD.nanorc` — for **Arch Linux package build scripts**.

## Installation

Install the syntax highlighter definitions to a directory of your choice (for example `/usr/local/share/nano/`), and add the corresponding include lines to the end of the `/etc/nanorc` config file:

    include "/usr/local/share/nano/conf.nanorc"
    include "/usr/local/share/nano/mk.nanorc"
    include "/usr/local/share/nano/PKGBUILD.nanorc"

Later include lines can override earlier ones, so for example if you have a highlighter that handles a specific config file format, make sure to keep its include line *below* that for `conf.nanorc`.

## Usage

After enabling them in `/etc/nanorc`, nano will automatically use these highlighter definitions for files of the corresponding types. Unusually named files may be missed by the auto-detection, but you can always explicitly select the highlighting you want using the `-Y` command-line option:

    nano -Y conf /some/file
