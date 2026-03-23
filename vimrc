"scriptencoding utf-8

" =============================================================================
" Plugin Manager (vim-plug)
" =============================================================================
call plug#begin('~/.vim/plugged')
Plug 'plasticboy/vim-markdown'
call plug#end()

" =============================================================================
" General Settings
" =============================================================================
set nocompatible
filetype plugin indent on
syntax on

set number
set relativenumber
set fileencoding=utf-8

set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

set hlsearch
set incsearch
set ignorecase
set smartcase

set undofile
set undodir=~/.vim/undodir

set splitright
set splitbelow

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0

" =============================================================================
" Markdown Preview
" =============================================================================
let g:markdown_preview_win = -1

function! s:IsMarkdownPreviewOpen()
    if g:markdown_preview_win == -1 | return 0 | endif
    return win_id2win(g:markdown_preview_win) != 0
endfunction

function! s:CloseMarkdownPreview()
    if s:IsMarkdownPreviewOpen()
        let l:winnr = win_id2win(g:markdown_preview_win)
        execute l:winnr . 'wincmd w'
        bdelete!
    endif
    let g:markdown_preview_win = -1
endfunction

function! s:OpenBrowserPreview()
    let l:filepath = expand('%:p')
    if l:filepath == '' || !filereadable(l:filepath)
        echom 'Save the buffer first (:w)'
        return
    endif
    if &filetype != 'markdown' && expand('%:e') !~? '^\(md\|markdown\|mkd\)$'
        echom 'Not a markdown file'
        return
    endif

    let l:pyfile   = tempname() . '.py'
    let l:htmlfile = tempname() . '.html'

    call writefile([
        \ 'import sys, re, html as h',
        \ 'infile, outfile = sys.argv[1], sys.argv[2]',
        \ 'text = open(infile, encoding="utf-8").read()',
        \ 'try:',
        \ '    import markdown',
        \ '    try:',
        \ '        import pymdownx',
        \ '        exts = ["tables", "pymdownx.superfences"]',
        \ '    except ImportError:',
        \ '        exts = ["tables", "fenced_code"]',
        \ '    body = markdown.markdown(text, extensions=exts)',
        \ 'except ImportError:',
        \ '    parts = []',
        \ '    last = 0',
        \ '    for m in re.finditer(r"```(\w*)\n(.*?)```", text, flags=re.DOTALL):',
        \ '        parts.append(("t", text[last:m.start()]))',
        \ '        parts.append(("c", m.group(2)))',
        \ '        last = m.end()',
        \ '    parts.append(("t", text[last:]))',
        \ '    out = []',
        \ '    for kind, s in parts:',
        \ '        if kind == "c":',
        \ '            out.append("<pre><code>" + h.escape(s) + "</code></pre>")',
        \ '        else:',
        \ '            t = h.escape(s)',
        \ '            t = re.sub(r"^### (.+)$", r"<h3>\1</h3>", t, flags=re.M)',
        \ '            t = re.sub(r"^## (.+)$", r"<h2>\1</h2>", t, flags=re.M)',
        \ '            t = re.sub(r"^# (.+)$", r"<h1>\1</h1>", t, flags=re.M)',
        \ '            t = re.sub(r"^&gt; (.+)$", r"<blockquote>\1</blockquote>", t, flags=re.M)',
        \ '            t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)',
        \ '            t = re.sub(r"\*(.+?)\*", r"<em>\1</em>", t)',
        \ '            t = re.sub(r"`(.+?)`", r"<code>\1</code>", t)',
        \ '            out.append("<br>\n".join(t.split("\n")))',
        \ '    body = "".join(out)',
        \ 'css = "body{font-family:sans-serif;max-width:860px;margin:40px auto;padding:0 24px;line-height:1.6;background:#1e1e2e;color:#cdd6f4}h1,h2,h3{border-bottom:1px solid #45475a;padding-bottom:.3em;color:#cba6f7}a{color:#89b4fa}code{background:#313244;padding:2px 6px;border-radius:3px;color:#a6e3a1}pre{background:#313244;padding:16px;border-radius:6px;overflow-x:auto;position:relative}pre code{background:none;padding:0;color:#cdd6f4}.copy-btn{position:absolute;top:8px;right:8px;background:#45475a;color:#cdd6f4;border:none;border-radius:4px;padding:4px 8px;cursor:pointer;font-size:12px;opacity:0;transition:opacity .2s}pre:hover .copy-btn{opacity:1}.copy-btn.copied{background:#a6e3a1;color:#1e1e2e}blockquote{border-left:4px solid #45475a;margin:0 0 1em 0;padding:0 16px;color:#a6adc8}table{border-collapse:collapse;width:100%}th,td{border:1px solid #45475a;padding:6px 12px;text-align:left}th{background:#313244;color:#cba6f7}"',
        \ 'js = "<script>document.querySelectorAll(\"pre\").forEach(function(p){var b=document.createElement(\"button\");b.className=\"copy-btn\";b.textContent=\"Copy\";b.onclick=function(){var t=p.querySelector(\"code\")?p.querySelector(\"code\").innerText:p.innerText;navigator.clipboard.writeText(t).then(function(){b.textContent=\"Copied!\";b.classList.add(\"copied\");setTimeout(function(){b.textContent=\"Copy\";b.classList.remove(\"copied\")},2000)})};p.appendChild(b)})</script>"',
        \ 'page = "<!DOCTYPE html><html><head><meta charset=utf-8><title>Preview</title><style>{}</style></head><body>{}{}</body></html>".format(css, body, js)',
        \ 'open(outfile, "w", encoding="utf-8").write(page)',
        \ ], l:pyfile)

    " Use env vars for paths to avoid quoting issues with spaces
    let $MD_PY_SCRIPT = l:pyfile
    let $MD_PY_IN     = l:filepath
    let $MD_PY_OUT    = l:htmlfile

    " Always go through cmd.exe regardless of &shell (e.g. Git Bash)
    " Try python, python3, py (Windows Launcher) in order
    let l:ran = 0
    for l:py in ['python', 'python3', 'py']
        let l:out = system('cmd /c ' . l:py . ' "%MD_PY_SCRIPT%" "%MD_PY_IN%" "%MD_PY_OUT%"')
        if v:shell_error == 0
            let l:ran = 1
            break
        endif
    endfor
    if !l:ran
        echom 'Python not found. Install from https://www.python.org/downloads/ and check "Add to PATH"'
        return
    endif

    call system('cmd /c start "" "%MD_PY_OUT%"')
    redraw!
endfunction

function! s:OpenTerminalPreview()
    let l:filepath = expand('%:p')
    if l:filepath == '' || !filereadable(l:filepath)
        echom 'Save the buffer first (:w)'
        return
    endif
    if &filetype != 'markdown' && expand('%:e') !~? '^\(md\|markdown\|mkd\)$'
        echom 'Not a markdown file'
        return
    endif

    let $MD_PREVIEW_FILE  = l:filepath
    let $MD_PREVIEW_WIDTH = (&columns / 2) - 4

    if executable('glow')
        let l:render = 'glow -w "$MD_PREVIEW_WIDTH" -'
    elseif executable('python3')
        let l:render = 'python3 -c "import sys; from rich.console import Console; from rich.markdown import Markdown; c = Console(); c.print(Markdown(sys.stdin.read()))"'
    else
        echom 'Neither glow nor python3+rich found'
        return
    endif

    let l:script = tempname() . '.sh'
    call writefile(['#!/bin/sh', 'export PATH="$HOME/.local/bin:$PATH"', 'cat "$MD_PREVIEW_FILE" | ' . l:render], l:script)
    call setfperm(l:script, 'rwxr-xr-x')

    let l:origin_win = win_getid()
    execute 'vertical botright terminal ' . l:script
    let g:markdown_preview_win = win_getid()
    tnoremap <buffer> q <C-w>:call <SID>CloseMarkdownPreview()<CR>
    call win_gotoid(l:origin_win)
endfunction

function! ToggleMarkdownPreview()
    if has('win32') || has('win64')
        call s:OpenBrowserPreview()
    else
        if s:IsMarkdownPreviewOpen()
            call s:CloseMarkdownPreview()
        else
            call s:OpenTerminalPreview()
        endif
    endif
endfunction

" =============================================================================
" Keybindings
" =============================================================================
nnoremap <leader>p :call ToggleMarkdownPreview()<CR>
nnoremap <F4> :call ToggleMarkdownPreview()<CR>

" =============================================================================
" Auto-close preview on leaving markdown buffer (Unix only)
" =============================================================================
augroup MarkdownPreview
    autocmd!
    autocmd BufLeave *.md,*.markdown,*.mkd call s:CloseMarkdownPreview()
augroup END
