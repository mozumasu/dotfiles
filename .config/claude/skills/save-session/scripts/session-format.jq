def blockquote: split("\n") | map("> " + .) | join("\n");
def cap($n): if (.|length) > $n then (.[0:$n] + "\n…(truncated)") else . end;
def res_text:
  if type=="string" then .
  elif type=="array" then (map(select(.type=="text").text // "") | join("\n"))
  else tojson end;

. as $all
| ( [ $all[]
      | select(.type=="user" and (.message.content|type=="array"))
      | .message.content[] | select(.type=="tool_result")
      | { key: (.tool_use_id // ""),
          value: { is_error:(.is_error // false), text:(.content|res_text) } } ]
    | from_entries ) as $results
| [ $all[]
    | select(
        (.type=="assistant" and (.message.content|type=="array"))
        or
        (.type=="user" and ((.isMeta|not)) and ((.isSidechain|not))
          and ((.message.content|type=="string")
               or ((.message.content|type=="array") and (any(.message.content[]; .type=="text")))))
      )
  ] as $turns
| ( [ $turns[]
      | select(.type=="user")
      | (.message.content | if type=="string" then . else (map(select(.type=="text").text)|join("\n")) end) ]
    | (.[0] // "") ) as $title_src
| ( [ $turns[]
      | if .type=="user" then
          { role: "user",
            md: ( ( .message.content
                    | if type=="string" then . else (map(select(.type=="text").text)|join("\n")) end )
                  | blockquote ) }
        else
          { role: "assistant",
            md: ( [ .message.content[]
                    | if .type=="text" then (.text // "")
                      elif .type=="tool_use" then
                        ( ((.input.command // .input.file_path // .input.description // .input.prompt // "")
                           | tostring | gsub("\n";" ") | .[0:160]) ) as $arg
                        | ($results[.id] // {is_error:false, text:""}) as $r
                        | "<details>\n<summary>🔧 " + .name + (if $arg!="" then " — " + $arg else "" end) + "</summary>\n\n"
                          + "```json\n" + ((.input|tojson) | cap(2000)) + "\n```\n\n"
                          + "**結果**: " + (if $r.is_error then "❌" else "✅" end)
                          + (if (($r.text|gsub("\\s";"")|length) > 0)
                             then "\n\n```\n" + ($r.text | cap(3000)) + "\n```" else "" end)
                          + "\n</details>"
                      else empty end ]
                  | map(select(. != null and . != "")) | join("\n\n") ) }
        end ]
    | map(select((.md // "") | gsub("\\s";"") | length > 0)) ) as $items
| ( reduce $items[] as $it ([];
      if (length > 0) and (.[-1].role == $it.role)
      then (.[0:-1] + [{ role: $it.role, md: (.[-1].md + "\n\n" + $it.md) }])
      else . + [$it] end) ) as $merged
| ( [ $merged[]
      | (if .role=="user" then "### 👤 User\n\n" else "### 🤖 Assistant\n\n" end) + .md ] ) as $blocks
| { count: ($merged | length),
    title_src: $title_src,
    body: ($blocks | join("\n\n---\n\n")) }
