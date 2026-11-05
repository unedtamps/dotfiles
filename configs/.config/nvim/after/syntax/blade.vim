" Blade syntax highlighting
" Load HTML syntax as base (must unset b:current_syntax so html.vim doesn't skip)
let s:save_syntax = get(b:, 'current_syntax', '')
unlet! b:current_syntax
runtime! syntax/html.vim
let b:current_syntax = 'blade'

" ── Variables ────────────────────────────────────────────────────────────────
syn match bladeVariable /\$[a-zA-Z_][a-zA-Z0-9_]*/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock
syn match bladeVariable /\$[a-zA-Z_][a-zA-Z0-9_]*\(\->\|\.\)[a-zA-Z_][a-zA-Z0-9_]*/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock
syn match bladeVariable /\$[a-zA-Z_][a-zA-Z0-9_]*\[[^\]]*\]/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock

" ── Echo expressions ─────────────────────────────────────────────────────────
" {{ expr }} - escaped output
syn region bladeEcho matchgroup=bladeDelimiter start="{{" end="}}" contains=bladeVariable,bladePhpFunc,bladeOperator,bladeTernary,bladeNumber keepend
" {!! expr !!} - unescaped output
syn region bladeRawEcho matchgroup=bladeDelimiter start="{!!" end="!!}" contains=bladeVariable,bladePhpFunc,bladeOperator,bladeTernary,bladeNumber keepend
" @{{ expr }} - escaped literal curly braces
syn region bladeEscapedEcho matchgroup=bladePreProc start="@{{" end="}}" contains=bladeVariable keepend

" ── Blade comments ──────────────────────────────────────────────────────────
syn region bladeComment start="{{--" end="--}}" contains=bladeTodo containedin=ALLBUT,bladeEcho,bladeRawEcho
syn keyword bladeTodo TODO FIXME HACK XXX NOTE contained

" ── Control flow directives ─────────────────────────────────────────────────
syn keyword bladeConditional @if @elseif @else @unless @endunless @isset @endisset @empty @endempty containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeConditional /@if\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeConditional /@elseif\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeConditional /@unless\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeConditional /@isset\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeConditional /@empty\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" Auth directives
syn keyword bladeAuthDirective @auth @endauth @guest @endguest containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeAuthDirective /@auth\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeAuthDirective /@guest\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" Authorization
syn keyword bladeCanDirective @can @cannot @endcan @endcannot containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeCanDirective /@can\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeCanDirective /@cannot\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Loop directives ─────────────────────────────────────────────────────────
syn keyword bladeLoop @for @endforeach @foreach @endforelse @forelse @while @endwhile @continue @break containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLoop /@for\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLoop /@foreach\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLoop /@forelse\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLoop /@while\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Layout / section directives ─────────────────────────────────────────────
syn keyword bladeLayout @extends @section @show @endsection @yield @parent containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLayout /@extends\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLayout /@section\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeLayout /@yield\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Component / slot directives ─────────────────────────────────────────────
syn keyword bladeComponent @component @endcomponent @slot @endslot @props @aware containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeComponent /@component\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeComponent /@slot\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeComponent /@props\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Include directives ──────────────────────────────────────────────────────
syn keyword bladeInclude @include @includeIf @includeWhen @includeUnless @includeFirst @each containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@include\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@includeIf\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@includeWhen\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@includeUnless\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@includeFirst\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeInclude /@each\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Stack directives ────────────────────────────────────────────────────────
syn keyword bladeStack @push @endpush @pushOnce @endPushOnce @prepend @endPrepend containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeStack /@push\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeStack /@pushOnce\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeStack /@prepend\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── PHP / raw blocks ────────────────────────────────────────────────────────
syn region bladePhpBlock matchgroup=bladePreProc start="@php" end="@endphp" contains=bladeVariable,bladePhpFunc,bladeOperator,bladeNumber keepend
syn keyword bladePreProc @json @verbatim @endverbatim containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladePreProc /@json\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Error handling ──────────────────────────────────────────────────────────
syn keyword bladeError @error @enderror containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeError /@error\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Debugging ───────────────────────────────────────────────────────────────
syn keyword bladeDebug @dd @dump containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── CSRF / method ───────────────────────────────────────────────────────────
syn keyword bladeHelper @csrf @method containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeHelper /@method\s*(/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── once ────────────────────────────────────────────────────────────────────
syn keyword bladeOnce @once @endonce containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── PHP functions inside echo ──────────────────────────────────────────────
syn keyword bladePhpFunc strlen substr strtolower strtoupper str_replace array_get array_pluck collect optional empty isset containedin=bladeEcho,bladeRawEcho,bladePhpBlock

" ── Operators ───────────────────────────────────────────────────────────────
syn match bladeOperator /===\|!==\|==\|!=\|<=\|>=\|||\|&&\|!\||\|\.\|\.\.\|??\|=>/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock
syn match bladeTernary /?/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock

" ── Numbers ─────────────────────────────────────────────────────────────────
syn match bladeNumber /\<[0-9]\+\>/ containedin=bladeEcho,bladeRawEcho,bladePhpBlock

" ── Blade component tags <x-...> ────────────────────────────────────────────
syn match bladeComponentTag /<\/\?x-[a-zA-Z0-9_.-]*/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho
syn match bladeComponentAttr /:[a-zA-Z_][a-zA-Z0-9_]*/ containedin=ALLBUT,bladeComment,bladeEcho,bladeRawEcho

" ── Highlighting ────────────────────────────────────────────────────────────
hi def link bladeVariable        Identifier
hi def link bladeDelimiter       Delimiter
hi def link bladeEcho            Special
hi def link bladeRawEcho         WarningMsg
hi def link bladeEscapedEcho     PreProc
hi def link bladeComment         Comment
hi def link bladeTodo            Todo
hi def link bladeConditional     Conditional
hi def link bladeLoop            Repeat
hi def link bladeLayout          Include
hi def link bladeComponent       Type
hi def link bladeInclude         Include
hi def link bladeStack           PreProc
hi def link bladePreProc         PreProc
hi def link bladeAuthDirective   Conditional
hi def link bladeCanDirective    Conditional
hi def link bladeError           Error
hi def link bladeDebug           Debug
hi def link bladeHelper          Macro
hi def link bladeOnce            PreProc
hi def link bladePhpFunc         Function
hi def link bladeOperator        Operator
hi def link bladeTernary         Operator
hi def link bladeNumber          Number
hi def link bladeComponentTag    Type
hi def link bladeComponentAttr   Identifier
