scriptencoding utf-8
" fcitx.vim  记住插入模式小企鹅输入法的状态
" Author:       lilydjwg
" Maintainer:   lilydjwg
" Last Change:  2011年1月29日
" ---------------------------------------------------------------------
" Load Once:

finish

if (has("win32") || has("win95") || has("win64") || has("win16"))
  " Windows 下不要载入
  finish
endif
if !exists('$DISPLAY') "没有 X，不要载入
  finish
endif
if &cp || exists("g:loaded_fcitx") || !executable("fcitx")
  finish
endif
if !has("python3")
  echohl WarningMsg
  echomsg "fcitx.vim: 没有 Python3 支持，尝试使用旧版本。"
  echohl None
  runtime so/fcitx.vim
  finish
endif
let s:fcitxsocketfile = expand('/tmp/fcitx-socket-$DISPLAY')
if !filewritable(s:fcitxsocketfile) "try again
  if strridx(s:fcitxsocketfile, '.') > 0
    let s:fcitxsocketfile = strpart(s:fcitxsocketfile, 0,
	  \ strridx(s:fcitxsocketfile, '.'))
  else
    let s:fcitxsocketfile = s:fcitxsocketfile . '.0'
  endif
endif
if !filewritable(s:fcitxsocketfile)
  echohl WarningMsg
  echomsg "没有找到 fcitx 的 socket 文件，fcitx.vim 没有载入。"
  echohl None
  finish
endif
let s:keepcpo = &cpo
let g:loaded_fcitx = 1
set cpo&vim
" ---------------------------------------------------------------------
" Functions:
python3 <<ENDPYTHON
import os
import vim
import socket
import struct
FCITX_STATUS = struct.pack('i', 0)
FCITX_OPEN   = struct.pack('i', 1 | (1 << 16))
FCITX_CLOSE  = struct.pack('i', 1)
INT_SIZE     = struct.calcsize('i')
fcitxsocketfile = vim.eval('s:fcitxsocketfile')

def fcitxtalk(command=None):
  sock = socket.socket(socket.AF_UNIX)
  try:
    sock.connect(fcitxsocketfile)
  except socket.error:
    vim.command('echohl WarningMsg | echo "fcitx.vim: socket 连接出错" | echohl NONE')
    return
  try:
    if not command:
      sock.send(FCITX_STATUS)
      return struct.unpack('i', sock.recv(INT_SIZE))[0]
    elif command == 'c':
      sock.send(FCITX_CLOSE)
    elif command == 'o':
      sock.send(FCITX_OPEN)
    else:
      raise ValueError('未知命令')
  finally:
    sock.close()

def fcitx2en():
  if fcitxtalk() == 2:
    vim.command('let b:inputtoggle = 1')
    fcitxtalk('c')

def fcitx2zh():
  if vim.eval('exists("b:inputtoggle")') == '1':
    if vim.eval('b:inputtoggle') == '1':
      fcitxtalk('o')
      vim.command('let b:inputtoggle = 0')
  else:
    vim.command('let b:inputtoggle = 0')
ENDPYTHON
" ---------------------------------------------------------------------
" Autocmds:
au InsertLeave * py3 fcitx2en()
au InsertEnter * py3 fcitx2zh()
" ---------------------------------------------------------------------
"  Restoration And Modelines:
let &cpo=s:keepcpo
unlet s:keepcpo
" vim:fdm=expr:fde=getline(v\:lnum-1)=~'\\v"\\s*-{20,}'?'>1'\:1
