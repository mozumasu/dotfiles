; extends

; ファイル先頭以外の frontmatter (Slidev のスライド区切り等) は
; markdown parser が setext_heading として解釈するため、
; key: value で始まる見出し段落を YAML としてハイライトする
((setext_heading
  (paragraph) @injection.content)
  (#lua-match? @injection.content "^%w+%s*:")
  (#set! injection.language "yaml")
  (#set! injection.include-children))
