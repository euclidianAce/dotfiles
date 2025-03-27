if exists("b:current_syntax")
	finish
endif

" This is specifically for C23

let s:cpo_save = &cpo
set cpo&vim

syntax case match

syntax keyword cDeprecated
	\ _Static_assert
	\ _Alignof
	\ _Alignas
	\ _Thread_local
	\ _Bool

syntax keyword cKeyword
	\ while
	\ break
	\ case
	\ continue
	\ default
	\ do
	\ else
	\ for
	\ goto
	\ if
	\ return
	\ switch
	\ _Generic
	\ static_assert
	\ asm
	\ __asm__

syntax keyword cOperator
	\ alignof
	\ sizeof
	\ typeof
	\ typeof_unqual

" iso646.h
syntax keyword cOperator
	\ and and_eq
	\ bitand bitor
	\ compl
	\ not not_eq
	\ or or_eq
	\ xor xor_eq

syntax keyword cStorageClass
	\ register
	\ restrict
	\ extern
	\ inline
	\ alignas
	\ static
	\ thread_local
	\ constexpr

syntax keyword cQualifier
	\ _Atomic
	\ volatile
	\ const

syntax keyword cLiteral
	\ nullptr
	\ false
	\ true

syntax keyword cType
	\ struct
	\ union
	\ enum
	\ typedef
	\ nullptr_t
	\ _Imaginary
	\ _BitInt
	\ int
	\ long
	\ short
	\ signed
	\ float
	\ auto
	\ unsigned
	\ void
	\ bool
	\ char
	\ double
	\ _Complex
	\ _Decimal128
	\ _Decimal32
	\ _Decimal64

syntax match cOperator /\v[-=*/+<>&^!|?%~]/
syntax match cDelimiter /[{}(),.:;\[\]]/
syntax match cDelimiter /->/

syntax match cDecDigits "0" nextgroup=cNumberSuffix
syntax match cDecDigits /[1-9][0-9']*/ contains=cNumberQuote nextgroup=cNumberSuffix

syntax match cNumberBase /0[bB]/ nextgroup=cBinaryDigits
syntax match cBinaryDigits /[01']\+/ contained contains=cNumberQuote,cBinaryOne,cBinaryZero nextgroup=cNumberSuffix
syntax match cBinaryZero "0" contained containedin=cBinaryDigits
syntax match cBinaryOne "1" contained containedin=cBinaryDigits

syntax match cNumberBase /0[xX]/ nextgroup=cHexDigits
syntax match cHexDigits /[0-9a-fA-F']\+/ contained contains=cNumberQuote nextgroup=cNumberSuffix

syntax match cNumberQuote "'" contained containedin=cBinaryDigits,cHexDigits,cDecDigits

syntax match cNumberSuffix /[uU][lL]\{0,2\}/ contained
syntax match cNumberSuffix /[lL]\{1,2\}/ contained
syntax match cNumberSuffix /[uU]\?[wW][bB]/ contained

syntax match cIdentifierUnderscore /_/ contained
syntax match cIdentifier /\K\k*/ contains=cIdentifierUnderscore

syntax match cComment /\/\/.*/
syntax region cComment start="\/\*" end="\*\/"

syntax match cStringEscape /\\[0abtnvfr"\\]/ contained
syntax match cStringEscape /\\x[0-9a-fA-F][0-9a-fA-F]/ contained
syntax region cString start=/"/ end=/"/ skip=/\\"/ contains=cStringEscape

syntax match cCharacter /'.'/
syntax match cCharacter /'\\.'/

syntax match cPreprocessor /#/

syntax match cPreprocessor /#\s*include\s*"[^"]*"/
syntax match cPreprocessor /#\s*include\s*<[^"]*>/

syntax match cPreprocessor /#\s*define/
syntax match cPreprocessor /#\s*undef/

syntax match cPreprocessor /#\s*if/
syntax match cPreprocessor /#\s*ifdef/
syntax match cPreprocessor /#\s*ifndef/

syntax match cPreprocessor /#\s*elif/
syntax match cPreprocessor /#\s*elifdef/
syntax match cPreprocessor /#\s*elifndef/

syntax match cPreprocessor /#\s*else/

syntax match cPreprocessor /#\s*endif/

syntax match cPreprocessor /#\s*line/

syntax match cPreprocessor /#\s*embed/

syntax match cPreprocessor /#\s*error/
syntax match cPreprocessor /#\s*warning/
syntax match cPreprocessor /#\s*pragma/

syntax match cPreprocessor /\\/

syntax keyword cPreprocessor defined
syntax keyword cPreprocessor _Pragma
syntax keyword cPreprocessor __VA_ARGS__ __VA_OPT__
syntax keyword cPreprocessor __FILE__ __LINE__
syntax keyword cPreprocessor __STDC__ __STDC_VERSION__
syntax keyword cPreprocessor __has_include

syntax region cAttribute start=/\[\[/ end=/\]\]/

" some standard library stuff

syntax keyword cType
	\ int8_t int16_t int32_t int64_t
	\ uint8_t uint16_t uint32_t uint64_t
	\ size_t ptrdiff_t
	\ intptr_t uintptr_t
	\ intmax_t uintmax_t
	\ maxalign_t
	\ va_list
	\ FILE
	\ errno_t

syntax keyword cConstant
	\ EOF
	\ NULL

" my libcw stuff

syntax keyword cOperator
	\ cw_cast
	\ cw_cast_ignore_qualifiers
	\ cw_ptr_remove_qualifiers
	\ cw_reinterpret

syntax keyword cType
	\ cw_size
	\ cw_address
	\ cw_machine_word cw_signed_machine_word
	\ cw_status
	\ cw_i8 cw_i16 cw_i32 cw_i64 cw_i128
	\ cw_n8 cw_n16 cw_n32 cw_n64 cw_n128
	\ cw_iteration_decision
	\ cw_source_location
	\ cw_storage_element
	\ cw_bytes cw_bytes_mut
	\ cw_buffer
	\ cw_userdata
	\ cw_bitset
	\ cw_allocator
	\ cw_allocator_vtable
	\ cw_sink
	\ cw_sink_vtable

syntax keyword cKeyword
	\ cw_inline
	\ cw_discard

syntax keyword cConstant
	\ cw_success
	\ cw_failure

hi link cKeyword Keyword
hi link cOperator Operator
hi link cStorageClass Type
hi link cQualifier Type
hi link cLiteral Constant
hi link cType Type
hi link cDelimiter Delimiter
hi link cPreprocessor PreProc
hi link cHexDigits Constant
hi link cDecDigits Constant
hi link cComment Comment
hi link cStringEscape Special
hi link cString Constant
hi link cCharacter Constant
hi link cIdentifier Identifier
hi link cIdentifierUnderscore Delimiter
hi link cBinaryDigits Constant
hi link cBinaryZero Delimiter
hi link cBinaryOne Constant
hi link cNumberBase Comment
hi link cNumberQuote Delimiter
hi link cNumberSuffix Comment
hi link cAttribute Delimiter
hi link cDeprecated Error
hi link cConstant Constant

let b:current_syntax = "c"

let &cpo = s:cpo_save
unlet s:cpo_save
