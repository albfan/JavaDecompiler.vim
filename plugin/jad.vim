if exists("loaded_jad") || &cp || exists("#BufReadPre#*.class")
  finish
endif
let loaded_jad = 1

" add your preferable flags after "jad" (for instance "jad -f -dead -ff -a")
let decompiler_command = "jad"

augroup class
  " Remove all jad autocommands
  au!
  " Enable editing of jaded files
  " set binary mode before reading the file
  autocmd BufReadPre,FileReadPre	*.class  set bin
  autocmd FileReadPost,BufEnter	*.class  call s:read(decompiler_command, expand("<afile>:r"))
augroup END

" Function to check that executing "cmd [-f]" works.
" The result is cached in s:have_"cmd" for speed.
fun s:check(cmd)
  let name = substitute(a:cmd, '\(\S*\).*', '\1', '')
  if !exists("s:have_" . name)
    let e = executable(name)
    if e < 0
      let r = system(name . " --version")
      let e = (r !~ "not found" && r != "")
    endif
    exe "let s:have_" . name . "=" . e
  endif
  exe "return s:have_" . name
endfun

" After reading decompiled file: Decompiled text in buffer with "cmd"
fun s:read(cmd, filename)
  " don't do anything if the cmd is not supported
  if !s:check(a:cmd)
    return
  endif
  let jadfile = a:filename . ".jad"
  let orig  = a:filename . ".class"
  " now we have no binary file, so set 'nobinary'
  let buffernumber = bufnr(jadfile)

  if (buffernumber >= 0)
     execute "buffer" buffernumber
  else 
     " make 'patchmode' empty, we don't want a copy of the written file
     let pm_save = &pm
     set pm =
     " set 'modifiable'
     set ma
     set nobin
     "Split and show code in a new window
     g/.*/d
     execute "silent r !" a:cmd . " -p " . orig
     1
     " set file name, type and file syntax to java
     execute ":file " . jadfile
     set ft      =java
     set syntax  =java
     " recover global variables
     let &pm     = pm_save
  endif
endfun
