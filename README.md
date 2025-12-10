# datho7561 Neovim config

This is based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), but I've hacked in a couple bug fixes and removed a lot of documentation from it.

### Getting started

Put init.lua into `~/.config/nvim/init.lua`.

Hopefully all the plugins and lsps get automatically installed.

### Keybindings

These are just the ones I added, the default neovim ones also work.

- `<space>gd`: go to definition
- `<space>Gd`: go to type definition
- `<space>r`: rename
- `<space>a`: activate code action under cursor
- `<space>gr`: open quick pick window with references
- `<space>lu`: update neovim plugins
- `<space>gx`: go to hyperlink
- `<space>f`: interactively search for files in subdirectories
- `<space>/`: live grep
- `<space>n`: quick pick window to switch between open files
- `<space>F`: format file

### To configure the servers

Go to `local servers = {` in `init.lua`, then add a `settings` key to the approriate server with the settings to use.
I'm pretty sure all the settings have to be nested instead of flat.

