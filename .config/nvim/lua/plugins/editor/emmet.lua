return {
  "mattn/emmet-vim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "html", "javascriptreact", "typescriptreact", "php", "ejs", "svelte", "astro" },
  init = function()
    vim.cmd([[
      let g:user_emmet_leader_key='<c-y>'
      let g:user_emmet_settings = {
      \  'variables' : {
      \    'lang' : "ja"
      \  },
      \  'html' : {
      \    'indentation' : '  ',
      \    'snippets' : {
      \      'html:5': "<!DOCTYPE html>\n"
      \        ."<html lang=\"${lang}\">\n"
      \        ."<head>\n"
      \        ."\t<meta charset=\"${charset}\">\n"
      \        ."\t<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\n"
      \        ."\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
      \        ."\t<title></title>\n"
      \        ."</head>\n"
      \        ."<body>\n\t${child}|\n</body>\n"
      \        ."</html>",
      \    }
      \  }
      \}
    ]])
  end,
}
