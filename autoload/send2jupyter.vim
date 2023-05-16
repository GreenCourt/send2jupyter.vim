let s:cpo = &cpo
set cpo&vim

let g:jupyter_python = get(g:, "jupyter_python", "python3")

function send2jupyter#send() abort range
  if !exists("b:kernel_id")
    let l:out = system(g:jupyter_python, join([
          \ 'import json',
          \ 'import urllib.request',
          \ 'import jupyter_server.serverapp',
          \ 'servers = list(jupyter_server.serverapp.list_running_servers())',
          \ 'sessions = []',
          \ 'for s in servers:',
          \ '    req = urllib.request.Request("http://127.0.0.1:" + str(s["port"]) + s["base_url"] + "api/sessions?token=" + s["token"])',
          \ '    with urllib.request.urlopen(req) as res:',
          \ '        body = json.load(res)',
          \ '    suffix = "" if len(servers) == 1 else " @" + str(s["port"])',
          \ '    for b in body:',
          \ '        sessions.append((b["name"] + suffix, b["kernel"]["id"]))',
          \ 'print(json.dumps(sessions))',
          \ ], "\n"))
    if v:shell_error
      redraw | echohl ErrorMsg | echo l:out | echohl None
      return
    endif
    let l:sessions = json_decode(l:out)
    if empty(l:sessions) | redraw | echo "jupyter session not found" | return | endif
    let l:idx = inputlist(["Select session."] + map(copy(l:sessions), {idx, val -> "[" . (idx+1) . "] " . val[0]})) - 1
    if l:idx == -1 | return | endif
    let b:kernel_id = l:sessions[l:idx][1]
  endif

  let l:out = system(g:jupyter_python, join([
        \ 'import json',
        \ 'import jupyter_client',
        \ 'info = json.loads(r"""' . json_encode({"kernel_id" : b:kernel_id, "code" : s:get_visual_selection()}) . '""")',
        \ 'kc = jupyter_client.BlockingKernelClient()',
        \ 'kc.load_connection_file(jupyter_client.find_connection_file(info["kernel_id"]))',
        \ 'kc.execute(info["code"])',
        \ ], "\n"))
  if v:shell_error
    unlet b:kernel_id
    redraw | echohl ErrorMsg | echo l:out | echohl None
  endif
endfunction

function s:get_visual_selection() abort range
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0 | return '' | endif
  if visualmode()==nr2char(22) "Ctrl-V
    for i in range(len(lines))
      let lines[i] = lines[i][column_start - 1 : column_end - (&selection == 'inclusive' ? 1 : 2)]
    endfor
  elseif visualmode()=="v"
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
  endif
  return join(lines, "\n")
endfunction

let &cpo = s:cpo
unlet s:cpo
