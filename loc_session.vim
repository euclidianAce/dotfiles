let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/dotfiles
%argdel
$argadd locations.txt
edit locations.txt

syn match locNotImportantPart "\S\+"

syn match locImportantPart "\S\+\s\+->\s\+\S\+" transparent
syn match locWord "[^ $]\+" containedin=locImportantPart contained
syn match locEnvVar "$[^/]\+" containedin=locImportantPart contained
syn match locArrow " -> " containedin=locImportantPart contained

hi def link locWord Identifier
hi def link locEnvVar Special 
hi def link locArrow Operator
hi def link locNotImportantPart Comment

let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
