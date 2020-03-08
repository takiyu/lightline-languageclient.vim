# lightline-languageclient.vim

Bridge plugin between [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim) and [lightline](https://github.com/itchyny/lightline.vim) to show linter indicators on status line.

This is inspired by [lightline-lsc-nvim](https://github.com/Palpatineli/lightline-lsc-nvim) and [lightline-ale](https://github.com/maximbaz/lightline-ale).


## Installation

```viml
call dein#add('takiyu/lightline-languageclient.vim')
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
let g:lightline#languageclient#indicator_ns = 'N/S'
let g:lightline#languageclient#indicator_e = 'E:%d'
let g:lightline#languageclient#indicator_w = 'W:%d'
let g:lightline#languageclient#indicator_i = 'I:%d'
```
