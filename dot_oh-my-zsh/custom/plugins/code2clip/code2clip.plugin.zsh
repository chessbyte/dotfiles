# Oh My Zsh plugin: code2clip
# Copies the content of specified files and directories (recursively) to the clipboard.

code2clip() {
  # Use Zsh's option parsing
  zparseopts -D -E -- -include-json=include_json_flag

  local include_json=false
  if (( ${#include_json_flag} > 0 )); then
    include_json=true
  else
    include_json=false
  fi

  # Use a distinct name for the input array
  local -a input_items=("$@")

  if (( ${#input_items} == 0 )); then
    print -u2 "Usage: code2clip [--include-json] <item1> [item2] ..."
    print -u2 "Example: code2clip src/ components/ utils.js --include-json"
    return 1
  fi

  local file_contents=""
  # Use an associative array for efficient checking of explicitly provided items
  local -A explicit_items_map
  # Use distinct loop variable name 'item'
  for item in "${input_items[@]}"; do
      local abs_item_path
      # Resolve to absolute path for consistent checking, handle errors
      abs_item_path=$(realpath "$item" 2>/dev/null) || abs_item_path="$item" # Fallback if realpath fails
      explicit_items_map[$abs_item_path]=1
  done

  # --- Helper function definitions ---
  # Function returns 0 (true) if explicit, 1 (false) otherwise
  _code2clip_is_explicit_item() {
      local check_file="$1" # Keep argument name generic here
      local abs_check_file
      abs_check_file=$(realpath "$check_file" 2>/dev/null) || abs_check_file="$check_file"
      # Check if the absolute path exists as a key in the associative array
      [[ -v explicit_items_map[$abs_check_file] ]]
  }

  # Use distinct name 'item' for the argument
  _code2clip_process_item() {
    local item="$1"
    local base_item="$item"

    if [[ ! -e "$item" ]]; then
      print -u2 "Warning: Item '$item' does not exist."
      return
    fi

    local absolute_item_path
    absolute_item_path=$(realpath "$item" 2>/dev/null) || absolute_item_path="$item"

    # --- Conditional logic based on file type ---
    if [[ -d "$absolute_item_path" ]]; then
      # Loop variable 'file' is okay, it refers to found files within the item
      while IFS= read -r -d $'\0' file; do
         if [[ "$file" == *"/.git/"* || "$file" == *"/node_modules/"* ]]; then continue; fi
         if [[ "$file" =~ '\.(png|jpe?g|gif|svg|ico|webp|mp4|webm|mov|mp3|wav|ogg|woff2?|ttf|eot|pdf)$' ]]; then continue; fi

         # --- EXPLICIT $? CHECK for JSON ---
         if [[ "$file" == *.json ]] && ! $include_json; then
             _code2clip_is_explicit_item "$file" # Check using the renamed function
             local is_explicit_rc=$?
             if (( is_explicit_rc != 0 )); then
                 continue
             fi
         fi
         # --- End $? CHECK ---

         local rel_base_path="${base_item%/}/"
         local relative_path="${file#$rel_base_path}"
         if [[ "$relative_path" == "$file" ]]; then relative_path=$(basename "$file"); fi

         file_contents+="// $base_item/$relative_path\n"
         file_contents+="$(<"$file")\n\n"

      done < <(find "$absolute_item_path" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -print0)

    elif [[ -f "$absolute_item_path" ]]; then
      local file="$absolute_item_path"
      if [[ "$file" =~ '\.(png|jpe?g|gif|svg|ico|webp|mp4|webm|mov|mp3|wav|ogg|woff2?|ttf|eot|pdf)$' ]]; then
         _code2clip_is_explicit_item "$file" # Check using the renamed function
         local is_bin_explicit_rc=$?
         if ! ( [[ "$file" == *.json ]] && $include_json && (( is_bin_explicit_rc == 0 )) ); then
            print -u2 "Skipping binary/media file: $item"; return # Use original item name for message
         fi
      fi

      # --- EXPLICIT $? CHECK for JSON ---
      if [[ "$file" == *.json ]] && ! $include_json; then
          _code2clip_is_explicit_item "$file" # Check using the renamed function
          local is_explicit_rc=$?
          if (( is_explicit_rc != 0 )); then
              return
          fi
      fi
      # --- End $? CHECK ---

      file_contents+="// $item\n"
      file_contents+="$(<"$file")\n\n"
    else
       print -u2 "Warning: Item '$item' is neither a regular file nor a directory."
    fi
  } # --- End _code2clip_process_item ---

  # --- Main processing loop ---
  for item in "${input_items[@]}"; do
      _code2clip_process_item "$item" # Call using the renamed function
  done

  # --- Final steps ---
  if [[ -z "$file_contents" ]]; then print -u2 "No processable files found..."; return 1; fi

  local content_length=${#file_contents}
  local estimated_tokens=0
  if (( content_length > 0 )); then (( estimated_tokens = content_length / 4 )); fi

  local pbcopy_path=$(command -v pbcopy)
  local xclip_path=$(command -v xclip)

  if [[ -n "$pbcopy_path" && -x "$pbcopy_path" ]]; then
      print -n "$file_contents" | "$pbcopy_path"
  elif [[ -n "$xclip_path" && -x "$xclip_path" ]]; then
      print -n "$file_contents" | "$xclip_path" -selection clipboard
  else
      print -u2 "Error: No clipboard command found (pbcopy or xclip)."
      print -u2 "Current PATH: $PATH"
      print -u2 "--- File Contents (stdout fallback) ---"
      print -n "$file_contents"
      return 1
  fi

  print -u2 "Contents copied to clipboard - $content_length characters, approx. $estimated_tokens tokens"
}

# Define alias if not already defined
if ! type c2c >/dev/null 2>&1; then
  alias c2c='code2clip'
fi