if !has('nvim-0.9')
  echohl WarningMsg
  echom "ZenMode needs Neovim >= 0.9"
  echohl None
  finish
endif
command! -bar LazyDocker lua require("lazydocker").toggle()
