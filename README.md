# vim-dev-env

### package manager

[vim-plug](https://github.com/junegunn/vim-plug)


### LSP configuration

[lsp-zero](https://lsp-zero.netlify.app/v3.x/)

### Keymap

*lsp-zero*

| Keycode | Description |
|---|---|
| K | Displays hover information about the symbol under the cursor in a floating window. |
| gd | Jumps to the definition of the symbol under the cursor. |
| gD | Jumps to the declaration of the symbol under the cursor (some servers don't support). |
| gi | Lists all the implementations for the symbol under the cursor in the quickfix window. |
| go | Jumps to the definition of the type of the symbol under the cursor. |
| gr | Lists all the references to the symbol under the cursor in the quickfix window. |
| gs | Displays signature information about the symbol under the cursor in a floating window. |
| \<F2> | Renames all references to the symbol under the cursor. |
| \<F3> | Format code in current buffer. |
| \<F4> | Selects a code action available at the current cursor position. |
| gl | Show diagnostics in a floating window. |
| [d | Move to the previous diagnostic in the current buffer. |
| ]d | Move to the next diagnostic. |

*panel*

| Keycode | Description |
|---|---|
| Ctrl + b | open nvim-tree |
| Ctrl + g | open lazygit |
