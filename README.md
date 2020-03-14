# lightline-languageclient.vim

Bridge plugin between [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim) and [lightline](https://github.com/itchyny/lightline.vim) to show linter indicators on status line.

(Inspired by [lightline-lsc-nvim](https://github.com/Palpatineli/lightline-lsc-nvim) and [lightline-ale](https://github.com/maximbaz/lightline-ale))

## Why need this?
Other plugins and example codes are using `getqflist()` to get diagnostic results. However, it is not applicable for `fzf`/`Location-list`/`Disabled` settings in LanguageClient-neovim.

To support any kind of diagnostic lists, this plugin parsing raw state of LanguageClient-neovim.

## Installation

```viml
call dein#add('takiyu/lightline-languageclient.vim')
```
or
```toml
[[plugins]]
repo = 'takiyu/lightline-languageclient.vim'
```

## Dependency
* autozimu/LanguageClient-neovim
* itchyny/lightline.vim

## Configurations
### Lightline components
```viml
let g:lightline = {}

let g:lightline.component_expand = {
    \   'linter_errors': 'lightline#languageclient#errors',
    \   'linter_ok': 'lightline#languageclient#ok',
    \ }

let g:lightline.component_type = {
    \   'linter_errors': 'error',
    \   'linter_ok': 'left',
    \ }

let g:lightline.active = {
    \   'right': [[ 'linter_errors', 'linter_ok' ]],
    \ }

```

### Indicators (optional)
```viml
let g:lightline#languageclient#indicator_ok = 'OK'
let g:lightline#languageclient#indicator_lt = 'Linting'
let g:lightline#languageclient#indicator_fd = 'Failed'
let g:lightline#languageclient#indicator_e = 'E:%d'
let g:lightline#languageclient#indicator_w = 'W:%d'
let g:lightline#languageclient#indicator_i = 'I:%d'
```
