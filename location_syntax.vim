
syn match locNotImportantPart "\S\+"

syn match locImportantPart "\S\+\s\+->\s\+\S\+" transparent
syn match locWord "\S\+" containedin=locImportantPart contained
syn match locEnvVar "$\K\k*" containedin=locImportantPart contained
syn match locArrow " -> " containedin=locImportantPart contained

hi def link locWord Identifier
hi def link locEnvVar Special 
hi def link locArrow Operator
hi def link locNotImportantPart Comment

