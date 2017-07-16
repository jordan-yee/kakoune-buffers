# buflist++: names AND modified bool
# debug buffers (like *debug*, *lint*…) are excluded
decl str-list buffers_info

# used to handle [+] (modified) symbol in list
def -hidden refresh-buffers-info %{
  set global buffers_info ''
  # iteration over all buffers
  eval -no-hooks -buffer * %{
    set -add global buffers_info "%val{bufname}_%val{modified}"
  }
}

# used to handle # (alt) symbol in list
decl str alt_bufname
decl str current_bufname
# adjust this number to display more buffers in info
decl int max_list_buffers 42

hook global WinDisplay .* %{
  set global alt_bufname %opt{current_bufname}
  set global current_bufname %val{bufname}
}

def list-buffers -docstring 'populate an info box with a numbered buffers list' %{
  refresh-buffers-info
  %sh{
    # info title
    number=$(printf '%s\n' "$kak_opt_buffers_info" | tr ':' '\n' | wc -l)
    index=0
    printf "info -title '$number buffers' -- %%^"
    printf '%s\n' "$kak_opt_buffers_info" | tr ':' '\n' |
    while read info; do
      # limit lists too big
      index=$(($index + 1))
      if [ "$index" -gt "$kak_opt_max_list_buffers" ]; then
        printf '  …'
        break
      fi

      name=${info%_*}
      if [ "$name" = "$kak_bufname" ]; then
        printf "> %s" "$index - $name"
      elif [ "$name" = "$kak_opt_alt_bufname" ]; then
        printf "# %s" "$index - $name"
      else
        printf "  %s" "$index - $name"
      fi

      modified=${info##*_}
      if [ "$modified" = true ]; then
        printf " [+]"
      fi
      echo
    done
    printf ^\\n
  }
}

def buffer-first -docstring 'move to the first buffer in the list' 'buffer-by-index 1'

def buffer-last -docstring 'move to the last buffer in the list' %{
  refresh-buffers-info
  %sh{
    number=$(printf '%s\n' "$kak_opt_buffers_info" | tr ':' '\n' | wc -l)
    echo "buffer-by-index $number"
  }
}

def -hidden -params 1 buffer-by-index %{ %sh{
  index=0

  printf '%s\n' "$kak_buflist" | tr ':' '\n' |
  while read buf; do
    index=$(($index+1))
    if [ $index = $1 ]; then
      echo "b $buf"
    fi
  done
}}

def buffer-only -docstring 'delete all saved buffers except current one' %{ %sh{
  printf '%s\n' "$kak_buflist" | tr ':' '\n' |
  while read buf; do
    if [ "$buf" != "$kak_bufname" ]; then
      echo "try 'db $buf'"
    fi
  done
}}

def buffer-only! -docstring 'delete all buffers except current one' %{ %sh{
  printf '%s\n' "$kak_buflist" | tr ':' '\n' |
  while read buf; do
    if [ "$buf" != "$kak_bufname" ]; then
      echo "db! $buf"
    fi
  done
}}

def -hidden mode-buffers -params ..1 %{
  info -title  %sh{[ $1 = lock ] && echo "'buffers (lock)'" || echo 'buffers' } \
%{[1-9]: by index
a: alternate
b: list
d: delete
f: find
h: first
l: last
n: next
o: only
p: previous}
  on-key %{ %sh{
    case "$kak_key" in
      [1-9]) echo "buffer-by-index $kak_key" ;;
      a) echo exec 'ga' ;;
      b) echo list-buffers ;;
      d) echo delete-buffer ;;
      f) echo exec ':buffer<space>' ;;
      h) echo buffer-first ;;
      l) echo buffer-last ;;
      n) echo buffer-next ;;
      o) echo buffer-only ;;
      p) echo buffer-previous ;;
      # info hides the previous one
      *) echo info; esc=true ;;
    esac
    # repeat?
    if [ "$1" = lock ] && [ "$esc" != true ]; then
      echo ';mode-buffers lock;list-buffers'
    fi
  }}
}

# Suggested hook

#hook global WinDisplay .* list-buffers

# Suggested mappings

#map global user b :mode-buffers<ret> -docstring 'buffers…'
#map global user B ':mode-buffers lock<ret>' -docstring 'buffers (lock)…'

# Suggested aliases

#alias global bf buffer-first
#alias global bl buffer-last
#alias global bo buffer-only
#alias global bo! buffer-only!
