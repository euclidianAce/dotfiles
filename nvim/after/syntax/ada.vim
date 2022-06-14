syn match Type /\K\k*\s*'\s*\ze(/

syn match AdaNumberWithBase /\d\+#[a-zA-Z0-9_]\+#/
syn match AdaNumberBaseEnd /#/ contained containedin=AdaNumberWithBase
syn match AdaNumberContent /[a-zA-Z0-9_]\+/ contained containedin=AdaNumberWithBase nextgroup=AdaNumberBaseEnd
syn match AdaNumberBase /\d\+#/ contained containedin=AdaNumberWithBase nextgroup=AdaNumberContent
hi link AdaNumberBase Comment
hi link AdaNumberBaseEnd Comment
hi link AdaNumberContent Number
