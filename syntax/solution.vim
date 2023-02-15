" Vim syntax file
" Language: Visual Studio Solution Files
" Maintainer: Aris Karagiannidis
" Latest Revision: 15 February 2023

if exists("b:current_syntax")
  finish
endif

" nextgroup tells the editor what group it can expect after a match
"
"The skipwhite argument simply tells the editor to expect some
"whitespace (spaces or tabs) between the keyword and the number.

" Keywords
"syn keyword basicLanguageKeywords Project
"syn keyword syntaxElementKeyword Global nextgroup=
"
"syntax keyword {group} {keyword1} {keyword2}
"keywords overrule any other syntax item
"
"
"When the item depends on the "end" pattern to match we cannot use a region

"General code line. Defined first to have the least priority. Match from start
"to end

"syntax keyword {group} {keyword1} {keyword2}
"Starting with the file with the  Visual Studio Versions
syn keyword SectionStartCommand VisualStudioVersion nextgroup = VisualStudioVersionNumber
syn keyword SectionStartCommand MinimumVisualStudioVersion nextgroup = VisualStudioVersionNumber
syn keyword SectionStartCommand Project
syn keyword SectionStartCommand EndProject
syn keyword SectionStartCommand ProjectSection
syn keyword SectionStartCommand EndProjectSection
syn keyword SectionStartCommand GlobalSection
syn keyword SectionStartCommand EndGlobalSection
syn keyword SectionStartCommand Global
syn keyword SectionStartCommand EndGlobal
syn keyword SectionStartCommand preProject
syn keyword SectionStartCommand preSolution
syn keyword SectionStartCommand postSolution

"Constant Arguments. Maybe do then within a region
syntax keyword Headers SolutionItems
syntax keyword Headers SolutionConfigurationPlatforms
syntax keyword Headers ProjectConfigurationPlatforms
syntax keyword Headers SolutionProperties
syntax keyword Headers ExtensibilityGlobals

"Example Version Number 17.0.32126.317 Four groups of integers seperated by dots
syntax match VisualStudioVersionNumber /[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/ skipwhite

"Lines that start with # are comments also the line that start with Microsoft
syntax match SolutionComment /#.*/
syntax match SolutionComment /Microsoft.*/

syn match GuidNotContained /\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}/
syn match GuidContained /\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}/ contained


"When the "contained" argument is given, this item will not be recognized at
"the top level, but only when it is mentioned in the "contains" field of
"another match.

syn region xString start=/"/ end=/"/


"1. When multiple Match or Region items start in the same position, the item
"   defined last has priority.
"2. A Keyword has priority over Match and Region items.
"3. An item that starts in an earlier position has priority over items that
"   start in later positions.



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""                       Highligting Groups                                ""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

hi def link SectionStartCommand    Statement
hi def link VisualStudioVersionNumber Constant
hi def link Headers Constant
hi def link SolutionComment Comment

hi def link xString String

hi def link GuidContained Constant
hi def link GuidNotContained Constant
