#!/bin/bash
# Wizard Library
# Provides page-based interactive wizard with screen redrawing support
#
# Usage examples:
#
# 1. Simple wizard (single page with interactive loop):
#    wizard_simple "Title" "display_function" "Prompt: "
#    - display_function receives user input as first argument
#    - Returns: 0=continue, 1=exit, 2=redraw
#
# 2. Multi-page wizard:
#    wizard_init "Title"
#    wizard_register_page "page1_function"
#    wizard_register_page "page2_function"
#    wizard_run
#    - Each page function should return: 0=next, 1=back, 2=exit

# Wizard state
WIZARD_TITLE=""
WIZARD_CURRENT_PAGE=0
WIZARD_TOTAL_PAGES=0
WIZARD_PAGES=()
WIZARD_DATA=()  # Array to store data from pages
WIZARD_RESULT=""  # Final result/action

# Initialize wizard
wizard_init() {
  local title="$1"
  WIZARD_TITLE="$title"
  WIZARD_CURRENT_PAGE=0
  WIZARD_TOTAL_PAGES=0
  WIZARD_PAGES=()
  
  # Clear screen on init
  if [[ -t 2 ]]; then
    tput clear 2>/dev/null || clear 2>/dev/null || true
  fi
}

# Register a page function
wizard_register_page() {
  local page_func="$1"
  WIZARD_PAGES+=("$page_func")
  WIZARD_TOTAL_PAGES=${#WIZARD_PAGES[@]}
}

# Clear screen
wizard_clear() {
  if [[ -t 2 ]]; then
    tput clear 2>/dev/null || clear 2>/dev/null || true
  fi
}

# Display wizard header
wizard_header() {
  echo "" >&2
  if [[ -n "$WIZARD_TITLE" ]]; then
    msg_highlight "$WIZARD_TITLE" >&2
  fi
  if [[ $WIZARD_TOTAL_PAGES -gt 0 ]]; then
    echo -e "  \033[90mPage $((WIZARD_CURRENT_PAGE + 1)) of $WIZARD_TOTAL_PAGES\033[0m" >&2
  fi
  echo "" >&2
}

# Redraw current page
wizard_redraw() {
  wizard_clear
  wizard_header
  
  # Call current page function if exists
  if [[ $WIZARD_CURRENT_PAGE -ge 0 ]] && [[ $WIZARD_CURRENT_PAGE -lt $WIZARD_TOTAL_PAGES ]]; then
    local page_func="${WIZARD_PAGES[$WIZARD_CURRENT_PAGE]}"
    if [[ -n "$page_func" ]] && type "$page_func" >/dev/null 2>&1; then
      "$page_func"
    fi
  fi
}

# Display a page (wrapper for page functions)
wizard_page() {
  local page_func="$1"
  
  # Register page if not already registered
  local found=false
  for existing_page in "${WIZARD_PAGES[@]}"; do
    if [[ "$existing_page" == "$page_func" ]]; then
      found=true
      break
    fi
  done
  
  if [[ "$found" == "false" ]]; then
    wizard_register_page "$page_func"
  fi
  
  # Set current page
  WIZARD_CURRENT_PAGE=$((${#WIZARD_PAGES[@]} - 1))
  
  # Display page
  wizard_redraw
}

# Run wizard (execute all pages sequentially with navigation)
wizard_run() {
  local start_page="${1:-0}"
  WIZARD_CURRENT_PAGE=$start_page
  
  while true; do
    # Check bounds
    if [[ $WIZARD_CURRENT_PAGE -lt 0 ]]; then
      WIZARD_CURRENT_PAGE=0
    fi
    if [[ $WIZARD_CURRENT_PAGE -ge $WIZARD_TOTAL_PAGES ]]; then
      # Reached end, wizard completed successfully
      return 0
    fi
    
    wizard_redraw
    
    # Call current page function
    local page_func="${WIZARD_PAGES[$WIZARD_CURRENT_PAGE]}"
    if [[ -n "$page_func" ]] && type "$page_func" >/dev/null 2>&1; then
      # Page function should return:
      #   0 - continue to next page
      #   1 - go back to previous page
      #   2 - exit wizard (cancel)
      #   3 - stay on current page (redraw)
      if "$page_func"; then
        local exit_code=$?
        case $exit_code in
          1)
            # Go back
            if [[ $WIZARD_CURRENT_PAGE -gt 0 ]]; then
              WIZARD_CURRENT_PAGE=$((WIZARD_CURRENT_PAGE - 1))
            else
              # Already on first page, exit wizard
              return 2
            fi
            ;;
          2)
            # Exit wizard (cancel)
            return 2
            ;;
          3)
            # Stay on current page (redraw)
            continue
            ;;
          *)
            # Continue to next page (0 or any other value)
            WIZARD_CURRENT_PAGE=$((WIZARD_CURRENT_PAGE + 1))
            ;;
        esac
      else
        # Page function returned error, exit
        return 1
      fi
    else
      # No page function, skip to next
      WIZARD_CURRENT_PAGE=$((WIZARD_CURRENT_PAGE + 1))
    fi
  done
  
  return 0
}

# Get wizard data by key
wizard_get() {
  local key="$1"
  local default="${2:-}"
  # Search in WIZARD_DATA array (format: key=value)
  for item in "${WIZARD_DATA[@]}"; do
    if [[ "$item" =~ ^${key}= ]]; then
      echo "${item#${key}=}"
      return 0
    fi
  done
  echo "$default"
}

# Set wizard data
wizard_set() {
  local key="$1"
  local value="$2"
  # Remove existing entry
  local new_data=()
  for item in "${WIZARD_DATA[@]}"; do
    if [[ ! "$item" =~ ^${key}= ]]; then
      new_data+=("$item")
    fi
  done
  # Add new entry
  new_data+=("${key}=${value}")
  WIZARD_DATA=("${new_data[@]}")
}

# Simple wizard for single-page interactive loops (like domain management)
# This creates a single-page wizard that handles its own input loop
wizard_simple() {
  local title="$1"
  local display_func="$2"  # Function to display current state and handle input
  local prompt_text="${3:-Enter command: }"
  
  wizard_init "$title"
  
  # Display function wrapper that handles both display and input
  wizard_simple_display() {
    local input="${1:-}"
    
    # If input provided, process it
    if [[ -n "$input" ]]; then
      # Handle special commands first
      case "$input" in
        done|q|quit|exit)
          # Exit wizard
          return 1
          ;;
        refresh|r)
          # Redraw
          return 2
          ;;
        *)
          # Call display function to handle input
          if [[ -n "$display_func" ]] && type "$display_func" >/dev/null 2>&1; then
            "$display_func" "$input"
            local result=$?
            # Return the same result from display function
            return $result
          else
            # Redraw if no display function
            return 2
          fi
          ;;
      esac
    fi
    
    # No input - just display current state
    if [[ -n "$display_func" ]] && type "$display_func" >/dev/null 2>&1; then
      "$display_func"
    fi
    
    return 0
  }
  
  # Initial display
  wizard_clear
  wizard_header
  wizard_simple_display
  
  # Function to read input with character-by-character filtering for domains
  # Allows commands (done, remove, q, etc.) but filters domain input
  read_domain_input() {
    local input=""
    local char
    local is_command=false
    
    while IFS= read -rsn1 char </dev/tty 2>/dev/null || IFS= read -rsn1 char; do
      # Handle Enter key (empty char or newline)
      if [[ -z "$char" ]] || [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
        break
      fi
      # Handle Backspace (^H, \177, \b) and Delete
      if [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]] || [[ "$char" == $'\x7f' ]]; then
        if [[ ${#input} -gt 0 ]]; then
          # Remove last character from input
          input="${input%?}"
          # Reset command detection if input is empty
          if [[ ${#input} -eq 0 ]]; then
            is_command=false
          fi
          # Move cursor back, print space, move cursor back again
          printf "\b \b" >&2
        fi
        continue
      fi
      
      # Detect if this might be a command (starts with d, r, q, or space for "remove")
      if [[ ${#input} -eq 0 ]]; then
        if [[ "$char" == "d" ]] || [[ "$char" == "D" ]] || [[ "$char" == "r" ]] || [[ "$char" == "R" ]] || [[ "$char" == "q" ]] || [[ "$char" == "Q" ]]; then
          is_command=true
        fi
      elif [[ "$input" =~ ^(done|remove|q|quit|exit|refresh|r)[[:space:]]*$ ]] || [[ "$input" =~ ^remove[[:space:]]+ ]]; then
        is_command=true
      fi
      
      # If it's a command, allow all printable characters (including spaces for "remove 1")
      if [[ "$is_command" == "true" ]]; then
        if [[ "$char" =~ [[:print:]] ]]; then
          input+="$char"
          printf "%s" "$char" >&2
        fi
      else
        # For domain input, only accept valid domain characters: letters, numbers, dots, hyphens, underscores
        if [[ "$char" =~ ^[a-zA-Z0-9._-]$ ]]; then
          # Additional validation: cannot start with dot or hyphen
          if [[ ${#input} -eq 0 ]] && ([[ "$char" == "." ]] || [[ "$char" == "-" ]]); then
            # Ignore leading dot or hyphen
            continue
          fi
          # Additional validation: cannot have consecutive dots
          if [[ "$char" == "." ]] && [[ "${input: -1}" == "." ]]; then
            # Ignore consecutive dots
            continue
          fi
          input+="$char"
          printf "%s" "$char" >&2
        fi
        # Ignore all other characters silently for domain input
      fi
    done
    
    echo "$input"
  }
  
  # Interactive loop
  while true; do
    echo -n "$prompt_text" >&2
    local input=$(read_domain_input)
    echo "" >&2  # New line after input
    
    if [[ -z "$input" ]]; then
      wizard_redraw
      wizard_simple_display
      continue
    fi
    
    # Process input
    wizard_simple_display "$input"
    local result=$?
    
    case $result in
      1)
        # Done - exit wizard
        break
        ;;
      2)
        # Redraw
        wizard_redraw
        wizard_simple_display
        ;;
      *)
        # Continue (redraw)
        wizard_redraw
        wizard_simple_display
        ;;
    esac
  done
  
  return 0
}
