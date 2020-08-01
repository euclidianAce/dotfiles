
syn match cPosixType /\<\K\k*_t\>/
hi link cPosixType Type

syn match cFuncCall /\K\k*\ze(/
hi link cFuncCall Function

syn match cOp "[!<>=~^&|*%+-]\|/\ze[^/]"
hi link cOp Operator
