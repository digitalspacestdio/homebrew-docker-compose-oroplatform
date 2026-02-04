#!/bin/bash
# UI Functions Library
# Provides messaging, spinner animations, and interactive prompts

# Function to display informational messages with consistent formatting
msg_info() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[36m==> $1\033[0m"
}

# Function to display debug/trace messages (dark gray)
# Used for verbose output like "Executing: orodc command"
msg_debug() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[90m==> $1\033[0m"
}

# Function to display warning messages
msg_warning() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[33m==> Warning: $1\033[0m"
}

# Function to display success messages
msg_ok() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[32m==> $1\033[0m"
}

# Function to display error messages
msg_error() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[31m==> Error: $1\033[0m"
}

# Function to display critical danger warnings (bold red)
# Used for warnings about data deletion or destructive operations
msg_danger() {
  # Always write to stderr (>&2) to keep separate from command stdout
  >&2 echo -e "\033[1;31m==> WARNING: $1\033[0m"
}

# Function to display header messages (bold blue)
msg_header() {
  >&2 echo -e "\033[1;34m==> $1\033[0m"
}

# Function to display highlighted text (bold white)
msg_highlight() {
  >&2 echo -e "\033[1;37m$1\033[0m"
}

# Function to display key-value pair with different colors
# Key is bright blue (same as header), value is white/bold
msg_key_value() {
  local key="$1"
  local value="$2"
  >&2 echo -e "\033[1;34m==> ${key}:\033[0m \033[1m${value}\033[0m"
}

# Backward compatibility aliases
echo_info() { msg_info "$*"; }
echo_ok() { msg_ok "$*"; }
echo_warn() { msg_warning "$*"; }
echo_error() { msg_error "$*"; }
echo_header() { msg_header "$*"; }

# Spinner animation for long-running commands
show_spinner() {
  local pid=$1
  local message=$2
  local spinstr='|/-\'
  local delay=0.1

  # Only show spinner if stderr is connected to terminal (not redirected to file/pipe)
  # This ensures spinner animation works properly in interactive sessions
  if [[ -t 2 ]]; then
    # Hide cursor during spinner animation (write to stderr)
    tput civis 2>/dev/null || true

    while kill -0 "$pid" 2>/dev/null; do
      local temp=${spinstr#?}
      # Spinner always writes to stderr (>&2) to avoid mixing with command output
      printf "\r\033[36m==> %s %c\033[0m" "$message" "$spinstr" >&2
      spinstr=$temp${spinstr%"$temp"}
      sleep $delay
    done

    # Clear spinner line (write to stderr)
    printf "\r\033[K" >&2
    # Show cursor again (write to stderr)
    tput cnorm 2>/dev/null || true
  else
    # If not in terminal, just wait silently (e.g., when output is redirected)
    while kill -0 "$pid" 2>/dev/null; do
      sleep $delay
    done
  fi
}

show_spinner_with_progress() {
  local pid=$1
  local message=$2
  local expected_duration=${3:-0}
  local spinstr='|/-\'
  local delay=1
  local elapsed=0

  # Only show spinner if running in terminal (not captured)
  if [[ -t 2 ]]; then
    tput civis 2>/dev/null || true

    while kill -0 "$pid" 2>/dev/null; do
      local temp=${spinstr#?}

      if [[ $expected_duration -gt 0 ]]; then
        local remaining=$((expected_duration - elapsed))
        if [[ $remaining -lt 0 ]]; then
          remaining=0
        fi
        printf "\r\033[36m==> %s %c %d sec of ~%d\033[0m" "$message" "$spinstr" "$elapsed" "$expected_duration" >&2
      else
        printf "\r\033[36m==> %s %c %d sec\033[0m" "$message" "$spinstr" "$elapsed" >&2
      fi

      spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      elapsed=$((elapsed + 1))
    done

    printf "\r\033[K" >&2
    tput cnorm 2>/dev/null || true
  else
    # If not in terminal, just wait silently
    while kill -0 "$pid" 2>/dev/null; do
      sleep $delay
    done
  fi
}

# Execute command with spinner and log on error
# Usage: run_with_spinner "message" "command"
# Spinner is disabled if DEBUG=1 or VERBOSE=1 is set, or if command contains --verbose/-v flags
# Logs are written to /tmp and preserved on error for user inspection
run_with_spinner() {
  local message=$1
  shift
  local cmd="$*"

  # If DEBUG or VERBOSE mode is enabled, or command contains verbose flags, run directly without spinner
  # Show logs directly in verbose mode
  if [[ -n "${DEBUG:-}" ]] || [[ -n "${VERBOSE:-}" ]] || [[ "$cmd" =~ (--verbose|-vv) ]]; then
    msg_info "$message..."  # writes to stderr
    eval "$cmd"
    return $?
  fi

  # Run with spinner (no logs during execution)
  local log_file
  log_file=$(mktemp /tmp/orodc-output.XXXXXX)
  local exit_code=0

  # Run command in background: redirect both stdout and stderr to log file
  # This keeps command output separate from spinner animation (which writes to stderr)
  eval "$cmd" > "$log_file" 2>&1 &
  local cmd_pid=$!

  # Show spinner in foreground (writes to stderr of parent process)
  show_spinner $cmd_pid "$message"

  wait $cmd_pid || exit_code=$?

  # Special handling for docker-compose up: check if all containers are running or exited successfully
  # Containers are OK if they are either:
  # 1. Running (Healthy or Started)
  # 2. Exited with code 0
  if [[ $exit_code -ne 0 ]] && [[ "$cmd" =~ "up" ]]; then
    # Check if there are any failed containers (not "exited (0)" and not "Healthy")
    if ! grep -qE "exited \([1-9]|Error|failed" "$log_file"; then
      # No real errors found, all containers are either Healthy or exited (0)
      exit_code=0
    fi
  fi

  if [[ $exit_code -ne 0 ]]; then
    msg_error "Command failed (exit code: $exit_code)"  # writes to stderr
    echo "" >&2

    # Show last 100 lines of log on error
    if [[ -f "$log_file" ]] && [[ -s "$log_file" ]]; then
      local line_count=$(wc -l < "$log_file" 2>/dev/null || echo "0")
      if [[ $line_count -gt 100 ]]; then
        msg_info "Last 100 lines of output:"  # writes to stderr
        echo "" >&2
        tail -n 100 "$log_file" >&2  # writes to stderr
        echo "" >&2
      else
        # If log is 100 lines or less, show everything (write to stderr)
        cat "$log_file" >&2
        echo "" >&2
      fi
      msg_info "Full log available at: $log_file"  # writes to stderr
      echo "" >&2
    else
      msg_info "Full log available at: $log_file"  # writes to stderr
      echo "" >&2
    fi

    # Keep log file for user inspection
    return $exit_code
  fi

  # Remove log file on success
  rm -f "$log_file"
  msg_ok "$message completed"  # writes to stderr
  return 0
}

# Interactive selector with validation and retry
# Usage: prompt_selector "prompt text" "default" "option1:value1" "option2:value2" ...
prompt_selector() {
  local prompt="$1"
  local default="$2"
  shift 2
  local options=("$@")
  local choice=""

  while true; do
    read -r -p "$prompt" choice

    # Empty input - use default
    if [[ -z "$choice" ]]; then
      if [[ -n "$default" ]]; then
        echo "$default"
        return 0
      else
        msg_error "Input required"
        continue
      fi
    fi

    # Check if input is a number (option index)
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      local idx=$((choice - 1))
      if [[ $idx -ge 0 ]] && [[ $idx -lt ${#options[@]} ]]; then
        local option="${options[$idx]}"
        echo "${option#*:}"  # Return value part
        return 0
      fi
    fi

    # Check if input matches any value directly
    for option in "${options[@]}"; do
      local value="${option#*:}"
      if [[ "$choice" == "$value" ]]; then
        echo "$value"
        return 0
      fi
    done

    # Check if it could be a custom value (for IP address case)
    if [[ "$choice" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$choice" =~ ^[a-zA-Z0-9\.\-\_]+$ ]]; then
      echo "$choice"
      return 0
    fi

    # Invalid input - show error and retry
    msg_error "Invalid choice: '$choice'. Please try again."
  done
}

# Interactive selector with numbered list display
# Usage: prompt_select "prompt text" "default" "option1" "option2" ...
# Shows numbered list and allows selection by number
prompt_select() {
  local prompt="$1"
  local default="$2"
  shift 2
  local options=("$@")
  local result=""
  
  # CRITICAL: Restore terminal to normal mode at function start
  # This ensures we're not in raw mode from previous commands
  stty sane 2>/dev/null || true
  stty echo icanon 2>/dev/null || true
  
  # Debug: show what we received
  if [[ -n "${DEBUG:-}" ]]; then
    >&2 echo "DEBUG: prompt='$prompt', default='$default', options count=${#options[@]}"
    >&2 echo "DEBUG: options=(${options[*]})"
  fi
  
  # Check if we have options
  if [[ ${#options[@]} -eq 0 ]]; then
    >&2 echo "ERROR: No options provided!"
    echo "$default"
    return
  fi
  
  while true; do
    # Output to stderr to avoid interfering with return value
    >&2 echo -e "\033[36m==> $prompt\033[0m"
    >&2 echo ""
    
    local i=1
    for opt in "${options[@]}"; do
      if [[ "$opt" == "$default" ]]; then
        >&2 echo "  $i) $opt [default]"
      else
        >&2 echo "  $i) $opt"
      fi
      ((i++))
    done
    
    # Read from terminal
    # CRITICAL: Ensure terminal is in normal mode (wait for Enter)
    # Restore normal mode before each read to handle any mode changes
    stty sane 2>/dev/null || true
    stty echo icanon 2>/dev/null || true
    local selection
    >&2 echo -n "Select [1-${#options[@]}] (default: $default): "
    read -r selection </dev/tty
    >&2 echo ""
    
    # Empty input - use default
    if [[ -z "$selection" ]]; then
      result="$default"
      break
    fi
    
    # Check if input is a valid number
    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
      >&2 echo -e "\033[31mInvalid input: '$selection'. Please enter a number between 1 and ${#options[@]}.\033[0m"
      continue
    fi
    
    # Check if number is in valid range
    local idx=$((selection - 1))
    if [[ $idx -ge 0 && $idx -lt ${#options[@]} ]]; then
      result="${options[$idx]}"
      break
    else
      >&2 echo -e "\033[31mInvalid choice: '$selection'. Please enter a number between 1 and ${#options[@]}.\033[0m"
    fi
  done
  
  # Debug output if needed
  if [[ -n "${DEBUG:-}" ]]; then
    >&2 echo "DEBUG: prompt_select returned: '$result'"
  fi
  
  # Return selected value to stdout
  echo "$result"
}

# Prompt for yes/no with default (alias for confirm_yes_no for compatibility)
# Usage: prompt_yes_no "prompt text" "default" (default: yes or no)
# Returns: 0 for yes, 1 for no
prompt_yes_no() {
  confirm_yes_no "$@"
}

# Prompt for port number with validation
# Usage: prompt_port "prompt text" "default_port"
prompt_port() {
  local prompt="$1"
  local default="$2"
  local choice=""

  while true; do
    read -r -p "$prompt" choice

    # Empty input - use default
    if [[ -z "$choice" ]]; then
      if [[ -n "$default" ]]; then
        echo "$default"
        return 0
      else
        msg_error "Port number required"
        continue
      fi
    fi

    # Validate port number
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le 65535 ]]; then
      echo "$choice"
      return 0
    else
      msg_error "Invalid port: '$choice'. Port must be a number between 1 and 65535."
    fi
  done
}

# Prompt for yes/no confirmation with validation
# Usage: confirm_yes_no "prompt text" "default" (default: yes or no)
# Returns: 0 for yes, 1 for no
confirm_yes_no() {
  local prompt="$1"
  local default="${2:-no}"
  local answer=""
  local char
  local input_source="/dev/tty"

  if [[ ! -r /dev/tty ]]; then
    if [[ ! -t 0 ]]; then
      if [[ "$default" == "yes" ]]; then
        return 0
      fi
      return 1
    fi
    input_source="/dev/stdin"
  fi

  while true; do
    if [[ "$default" == "yes" ]]; then
      printf "\033[1;33m%s [Y/n]: \033[0m" "$prompt" >&2
    else
      printf "\033[1;33m%s [y/N]: \033[0m" "$prompt" >&2
    fi

    # Read input character by character, filtering only Latin letters and digits
    answer=""
    while IFS= read -rsn1 char <"$input_source" 2>/dev/null || IFS= read -rsn1 char; do
      # Handle Enter key (empty char or newline)
      if [[ -z "$char" ]] || [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
        break
      fi
      # Handle Backspace (^H, \177, \b) and Delete
      if [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]] || [[ "$char" == $'\x7f' ]]; then
        if [[ ${#answer} -gt 0 ]]; then
          # Remove last character from answer
          answer="${answer%?}"
          # Move cursor back, print space, move cursor back again
          printf "\b \b" >&2
        fi
        continue
      fi
      # Only accept Latin letters and digits - ignore all other characters silently
      if [[ "$char" =~ ^[a-zA-Z0-9]$ ]]; then
        answer+="$char"
        printf "%s" "$char" >&2
      fi
      # Ignore all other characters without any feedback
    done

    # Use default if empty input
    if [[ -z "$answer" ]]; then
      if [[ "$default" == "yes" ]]; then
        answer="y"
      else
        answer="n"
      fi
    fi
    
    # Always add newline after input
    echo "" >&2

    # Accept: y, yes, Y, YES, n, no, N, NO
    answer_lower="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"
    case "$answer_lower" in  # Convert to lowercase
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *)
        msg_error "Invalid input: '$answer'. Please enter 'y' (yes) or 'n' (no)."
        ;;
    esac
  done
}

# Read numeric choice interactively
# Usage: read_numeric_choice "prompt" "pattern" "default"
# Returns: selected choice via echo (use: choice=$(read_numeric_choice ...))
# Example: choice=$(read_numeric_choice "Your choice (1/2/3): " "^[1-3]$" "")
read_numeric_choice() {
  local prompt="$1"
  local pattern="${2:-^[0-9]+$}"
  local default="${3:-}"
  local choice=""

  printf "%s" "$prompt" >&2
  
  # Use regular read which waits for Enter key
  # Read from /dev/tty explicitly for better Mac compatibility
  IFS= read -r choice </dev/tty 2>/dev/null || IFS= read -r choice

  # Use default if empty input and default provided
  if [[ -z "$choice" ]] && [[ -n "$default" ]]; then
    choice="$default"
  fi

  # Validate pattern if provided
  if [[ -n "$choice" ]] && [[ "$choice" =~ $pattern ]]; then
    echo "$choice"
    return 0
  elif [[ -z "$choice" ]]; then
    # Empty choice is valid if no default
    echo ""
    return 0
  else
    # Invalid choice
    echo ""
    return 1
  fi
}
