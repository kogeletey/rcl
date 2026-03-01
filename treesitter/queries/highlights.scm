; RCL Treesitter Highlight Queries

; Keywords
(block
  "do" @keyword
  "end" @keyword)

; Identifiers (property names and block names)
(identifier) @variable

; Assignment operator
(assignment "=" @operator)

; Strings
(string) @string

; Numbers
(number) @number

; Arrays
(array "[" @punctuation.bracket
       "]" @punctuation.bracket)
(array "," @punctuation.delimiter)

; Comments
(comment) @comment
