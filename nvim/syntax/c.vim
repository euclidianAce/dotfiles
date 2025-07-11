if exists("b:current_syntax")
	finish
endif

" This is specifically for C23

let s:cpo_save = &cpo
set cpo&vim

syntax sync fromstart
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

" limits.h + stdint.h
syntax keyword cConstant
	\ BOOL_WIDTH
	\ CHAR_BIT
	\ SHRT_WIDTH   USHRT_WIDTH
	\ INT_WIDTH    UINT_WIDTH
	\ LONG_WIDTH   ULONG_WIDTH
	\ LLONG_WIDTH  ULLONG_WIDTH
	\ INTPTR_WIDTH UINTPTR_WIDTH
	\ INTMAX_WIDTH UINTMAX_WIDTH
	\ PTRDIFF_WIDTH
	\ SIZE_WIDTH
	\ WCHAR_WIDTH
	\ WINT_WIDTH
	\ BITINT_MAXWIDTH
	\ MB_LEN_MAX
	\
	\ SHRT_MIN   SHRT_MAX   USHRT_MAX
	\ INT_MIN    INT_MAX    UINT_MAX
	\ LONG_MIN   LONG_MAX   ULONG_MAX
	\ LLONG_MIN  LLONG_MAX  ULLONG_MAX
	\ INTPTR_MIN INTPTR_MAX UINTPTR_MAX
	\
	\ INT8_WIDTH  UINT8_WIDTH  INT_LEAST8_WIDTH  INT_FAST8_WIDTH
	\ INT16_WIDTH UINT16_WIDTH INT_LEAST16_WIDTH INT_FAST16_WIDTH
	\ INT32_WIDTH UINT32_WIDTH INT_LEAST32_WIDTH INT_FAST32_WIDTH
	\ INT64_WIDTH UINT64_WIDTH INT_LEAST64_WIDTH INT_FAST64_WIDTH

syntax keyword cOperator
	\ INT8_C UINT8_C
	\ INT16_C UINT16_C
	\ INT32_C UINT32_C
	\ INT64_C UINT64_C
	\ INTMAX_C UINTMAX_C

syntax keyword cPreprocessor __STDC_ENDIAN_NATIVE__ __STDC_ENDIAN_LITTLE__ __STDC_ENDIAN_BIG__

syntax keyword cStorageClass
	\ register
	\ extern
	\ inline
	\ alignas
	\ static
	\ thread_local
	\ constexpr

syntax keyword cQualifier
	\ _Atomic
	\ restrict
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

syntax match cUnimportant /_/ contained

syntax match cIdentifier /\K\k*/ contains=cUnimportant

syntax match cComment /\/\/.*/
syntax region cComment start="\/\*" end="\*\/"

syntax match cStringEscape /\\[0abtnvfr"\\]/ contained
syntax match cStringEscape /\\x[0-9a-fA-F][0-9a-fA-F]/ contained
syntax region cString start=/"/ end=/"/ skip=/\\"/ contains=cStringEscape

syntax match cCharacter /'.'/
syntax match cCharacter /'\\.'/
syntax match cCharacter /'\\x[0-9a-fA-F][0-9a-fA-F]'/

syntax match cPreprocessor /^\s*#/

syntax match cPreprocessor /^\s*#\s*include\s*"[^"]*"/
syntax match cPreprocessor /^\s*#\s*include\s*<[^"]*>/

syntax match cPreprocessor /^\s*#\s*define\>/
syntax match cPreprocessor /^\s*#\s*undef\>/

syntax match cPreprocessor /^\s*#\s*if\>/
syntax match cPreprocessor /^\s*#\s*ifdef\>/
syntax match cPreprocessor /^\s*#\s*ifndef\>/

syntax match cPreprocessor /^\s*#\s*elif/
syntax match cPreprocessor /^\s*#\s*elifdef/
syntax match cPreprocessor /^\s*#\s*elifndef/

syntax match cPreprocessor /^\s*#\s*else\>/

syntax match cPreprocessor /^\s*#\s*endif\>/

syntax match cPreprocessor /^\s*#\s*line\>/

syntax match cPreprocessor /^\s*#\s*embed\>/

syntax match cPreprocessor /^\s*#\s*error\>/
syntax match cPreprocessor /^\s*#\s*warning\>/
syntax match cPreprocessor /^\s*#\s*pragma\>/

syntax match cPreprocessor /\\/

syntax keyword cPreprocessor defined
syntax keyword cPreprocessor _Pragma
syntax keyword cPreprocessor __VA_ARGS__ __VA_OPT__
syntax keyword cPreprocessor __has_include __has_embed __has_c_attribute
syntax keyword cPreprocessor
	\ __FILE__ __LINE__ __DATE__ __TIME__
	\ __STDC__ __STDC_VERSION__ __STDC_HOSTED__
	\ __STDC_UTF_16__ __STDC_UTF_32__
	\ __STDC_EMBED_NOT_FOUND__ __STDC_EMBED_FOUND__ __STDC_EMBED_EMPTY__
	\ __STDC_ISO_10646__
	\ __STDC_MB_MIGHT_NEQ_WC__
	\ __STDC_ANALYZABLE__
	\ __STDC_LIB_EXT1__
	\ __STDC_NO_ATOMICS__
	\ __STDC_NO_COMPLEX__
	\ __STDC_NO_THREADS__
	\ __STDC_NO_VLA__
	\ __STDC_IEC_60559_BFP__
	\ __STDC_IEC_60559_DFP__
	\ __STDC_IEC_60559_COMPLEX__
	\ __STDC_IEC_60559_TYPES__

syntax keyword cDeprecated
	\ __STDC_IEC_559__ __STDC_IEC_559_COMPLEX__

syntax keyword cConstant __func__

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

syntax keyword cPreprocessor
	\ unreachable

syntax keyword cConstant
	\ EOF
	\ NULL

" my libcw stuff

syntax keyword cOperator
	\ cw_cast
	\ cw_cast_ignore_qualifiers
	\ cw_ptr_remove_qualifiers
	\ cw_cast_ignore_qualifiers
	\ cw_reinterpret
	\ cw_natural_last
	\ cw_integer_first cw_integer_last

syntax keyword cType
	\ cw_size cw_half_size
	\ cw_address
	\ cw_machine_word cw_signed_machine_word
	\ cw_machine_half_word cw_signed_machine_half_word
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
	\ cw_source
	\ cw_source_vtable
	\ cw_file

syntax keyword cKeyword
	\ cw_inline
	\ cw_discard

syntax keyword cConstant
	\ cw_success
	\ cw_failure
	\ cw_break
	\ cw_continue
	\ cw_machine_word_max
	\ cw_machine_word_bits

syntax keyword cUnimportant cw_in cw_out

syntax keyword cPreprocessor
	\ cw_current_os
	\ cw_config_freestanding
	\ cw_config_use_vla
	\ cw_config_use_builtins
	\ cw_config_use_memory_poisoning

" custom print formatting
syntax match cStringEscape /\~\(([^)]*)\)\?/ contained

syntax match cUnimportant /\<cw_/ contained

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
hi link cUnimportant Delimiter
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
