#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# CRITICAL: Reset terminal state at script start to prevent text highlighting
# This ensures clean terminal state even if parent process left attributes set
if [[ -t 2 ]]; then
  printf "\033[?2004l\033[?1l\033[?7h\033[?12l\033[?25h\033[0m" >&2
  tput sgr0 2>/dev/null || true
fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Helper function to run command via orodc and return to menu
# This function simply calls orodc with ORODC_IS_INTERACTIVE_MENU=1
# to ensure menu reflects 1:1 command line behavior
run_command_with_menu_return() {
  local cmd="$1"
  shift
  
  # Find orodc command
  local orodc_cmd="orodc"
  if ! command -v "$orodc_cmd" >/dev/null 2>&1; then
    # Fallback: try to find orodc in PATH or use script path
    orodc_cmd="${SCRIPT_DIR}/../../bin/orodc"
    if [[ ! -f "$orodc_cmd" ]]; then
      msg_error "orodc command not found"
      return 1
    fi
  fi
  
  # Show what command will be executed (for user feedback)
  msg_debug "Executing: orodc $cmd $*" >&2
  # Flush output buffers to ensure message is displayed before exec
  echo "" >&2
  
  # Execute command via orodc with ORODC_IS_INTERACTIVE_MENU=1
  # This tells orodc to return to menu after completion
  # Command executes exactly as it would from command line
  # bin/orodc handles menu return via execute_with_menu_return
  exec env ORODC_IS_INTERACTIVE_MENU=1 "$orodc_cmd" "$cmd" "$@"
}

# Show interactive menu
show_interactive_menu() {
  # CRITICAL: Initialize terminal state - disable problematic modes that cause text highlighting
  # Disable bracketed paste mode and other selection-related modes
  printf "\033[?2004l\033[?1l\033[?7h\033[?12l\033[?25h" >&2
  # Reset all terminal attributes immediately - CRITICAL
  tput sgr0 2>/dev/null || printf "\033[0m" >&2
  printf "\033[0m" >&2
  # Ensure normal terminal mode
  stty sane 2>/dev/null || true
  # Force reset of all attributes one more time
  printf "\033[0m" >&2
  
  # Handle Ctrl+C gracefully
  # Reset terminal attributes before exit to prevent text highlighting
  trap 'printf "\033[?2004l\033[0m\033[?25h" >&2; tput sgr0 2>/dev/null || true; stty sane 2>/dev/null || true; echo "" >&2; echo "" >&2; msg_info "Goodbye!" >&2; exit 0' SIGINT

  # Export VERBOSE if set, so all child processes inherit it
  if [[ -n "${VERBOSE:-}" ]]; then
    export VERBOSE
  else
    unset VERBOSE
  fi

  # Auto-register current environment if in project
  if [[ -n "${DC_ORO_NAME:-}" ]] && [[ -n "${DC_ORO_CONFIG_DIR:-}" ]]; then
    # We're in a project - register it if needed
    register_environment "${DC_ORO_NAME}" "$(pwd)" "${DC_ORO_CONFIG_DIR}" 2>/dev/null || true
  fi

  local current_status="uninitialized"
  local status_display=""
  local is_registered=false

  # Check if environment is registered
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    current_status=$(get_environment_status "${DC_ORO_NAME}" "$PWD")
    is_registered=$(is_environment_registered "${DC_ORO_NAME}" && echo "true" || echo "false")
  fi

  if [[ "$current_status" == "running" ]]; then
    if [[ "$is_registered" == "true" ]]; then
      status_display="\033[32mrunning\033[0m"
    else
      status_display="\033[32mrunning\033[0m \033[33m(unregistered)\033[0m"
    fi
  elif [[ "$current_status" == "uninitialized" ]]; then
    status_display="\033[33muninitialized\033[0m"
  else
    if [[ "$is_registered" == "true" ]]; then
      status_display="\033[31mstopped\033[0m"
    else
      status_display="\033[31mstopped\033[0m \033[33m(unregistered)\033[0m"
    fi
  fi
  
  # CRITICAL: Reset terminal state before clearing screen
  # Disable bracketed paste mode and other problematic modes
  printf "\033[?2004l\033[?1l\033[?7h\033[?12l\033[?25h" >&2
  # Reset all terminal attributes - CRITICAL to prevent text highlighting
  tput sgr0 2>/dev/null || printf "\033[0m" >&2
  printf "\033[0m" >&2
  # Restore normal terminal settings
  stty sane 2>/dev/null || true
  
  # Clear screen using tput (more reliable than clear command)
  tput clear 2>/dev/null || clear || true
  
  # Show cursor and ensure normal mode - reset again after clear
  tput sgr0 2>/dev/null || printf "\033[0m" >&2
  tput cnorm 2>/dev/null || printf "\033[?25h" >&2
  printf "\033[0m" >&2
  
  # Reset attributes before colored output - ensure clean state
  printf "\033[0m" >&2
  msg_info "Welcome to OroDC Interactive Menu!"
  echo "" >&2
  
  # Get terminal width and determine column layout
  local term_width=${COLUMNS:-80}
  if ! [[ "$term_width" =~ ^[0-9]+$ ]]; then
    # Try to get actual terminal width
    term_width=$(tput cols 2>/dev/null || echo "80")
    if ! [[ "$term_width" =~ ^[0-9]+$ ]]; then
      term_width=80
    fi
  fi
  
  # Determine column layout based on terminal width
  # Each column needs ~36 chars (32 for text + 4 for padding)
  # 3 columns: >= 150 chars (36*3 + margins)
  # 2 columns: >= 100 chars (36*2 + margins)
  # 1 column: < 100 chars
  local use_three_columns=false
  local use_two_columns=false
  if [[ $term_width -ge 150 ]]; then
    use_three_columns=true
  elif [[ $term_width -ge 100 ]]; then
    use_two_columns=true
  fi
  
  # Maximum text length per menu item (excluding "  X) " prefix)
  local max_text_length=32
  # Show current environment
  printf "\033[0m" >&2
  local env_display="${DC_ORO_NAME:--}"
  if [[ "$env_display" != "-" ]]; then
    echo -e "Current Environment: \033[1m${env_display}\033[0m ($status_display)" >&2
  else
    echo -e "Current Environment: \033[1m-\033[0m (\033[33mnot in project\033[0m)" >&2
  fi
  printf "\033[0m" >&2

  # Show current directory
  local display_dir="${DC_ORO_APPDIR:-$(pwd)}"
  if [[ -z "${DC_ORO_NAME:-}" ]]; then
    display_dir="-"
  fi

  if [[ "$display_dir" == "-" ]]; then
    echo -e "Current Directory: \033[90m-\033[0m" >&2
  else
    echo -e "Current Directory: $display_dir\033[0m" >&2
  fi
  printf "\033[0m" >&2
  # Show VERBOSE status
  if [[ -n "${VERBOSE:-}" ]]; then
    echo -e "VERBOSE mode: \033[32mON\033[0m" >&2
  else
    echo -e "VERBOSE mode: \033[90mOFF\033[0m" >&2
  fi
  printf "\033[0m" >&2
  echo "" >&2
  
  # Interactive selection with arrow keys
  local selected=1
  local total_options=23
  local choice=""
  
  # Function to truncate text to maximum length
  truncate_menu_text() {
    local text="$1"
    local max_len="${2:-32}"
    if [[ ${#text} -le $max_len ]]; then
      echo "$text"
    else
      echo "${text:0:$((max_len-3))}..."
    fi
  }
  
  # Function to render menu option with selection highlight
  render_menu_option() {
    local opt_num=$1
    local is_selected=$2
    local opt_text=$3
    local truncated_text=$(truncate_menu_text "$opt_text" "$max_text_length")
    
    if [[ $is_selected -eq 1 ]]; then
      # Use inverted colors for selection, but ensure reset after
      printf "  \033[7m%2d) %s\033[0m\033[27m\n" "$opt_num" "$truncated_text" >&2
      # Double reset to ensure attributes are cleared
      printf "\033[0m" >&2
    else
      printf "  %2d) %s\n" "$opt_num" "$truncated_text" >&2
    fi
  }
  
  # Function to format menu item text for multi-column layout
  format_menu_item() {
    local opt_num=$1
    local opt_text=$2
    # Account for "XX) " prefix (4 chars) when truncating
    local text_max_len=$((max_text_length - 4))
    local truncated_text=$(truncate_menu_text "$opt_text" "$text_max_len")
    printf "%2d) %s" "$opt_num" "$truncated_text"
  }
  
  # Function to calculate and return status_display
  calculate_status_display() {
    local current_status="uninitialized"
    local status_display=""
    local is_registered=false
    
    if [[ -n "${DC_ORO_NAME:-}" ]]; then
      current_status=$(get_environment_status "${DC_ORO_NAME}" "$PWD" 2>/dev/null || echo "uninitialized")
      is_registered=$(is_environment_registered "${DC_ORO_NAME}" 2>/dev/null && echo "true" || echo "false")
    fi
    
    if [[ "$current_status" == "running" ]]; then
      if [[ "$is_registered" == "true" ]]; then
        status_display="\033[32mrunning\033[0m"
      else
        status_display="\033[32mrunning\033[0m \033[33m(unregistered)\033[0m"
      fi
    elif [[ "$current_status" == "uninitialized" ]]; then
      status_display="\033[33muninitialized\033[0m"
    else
      if [[ "$is_registered" == "true" ]]; then
        status_display="\033[31mstopped\033[0m"
      else
        status_display="\033[31mstopped\033[0m \033[33m(unregistered)\033[0m"
      fi
    fi
    
    echo "$status_display"
  }
  
  # Function to redraw entire menu screen
  redraw_menu_screen() {
    local selected_option=$1
    local use_two_cols=$2
    local input_buf="${3:-}"
    local use_three_cols="${4:-false}"
    local cached_status_display="${5:-}"
    
    # Clear screen
    tput clear 2>/dev/null || clear || true
    
    # Redraw header
    printf "\033[0m" >&2
    msg_info "Welcome to OroDC Interactive Menu!" >&2 || true
    echo "" >&2
    
    # Redraw menu with selection
    display_menu_with_selection $selected_option $use_two_cols "$use_three_cols" || true
    
    # Redraw status (use cached value instead of recalculating)
    echo "" >&2
    printf "\033[0m" >&2
    local env_display="${DC_ORO_NAME:--}"
    if [[ "$env_display" != "-" ]]; then
      echo -e "Current Environment: \033[1m${env_display}\033[0m ($cached_status_display)" >&2
    else
      echo -e "Current Environment: \033[1m-\033[0m (\033[33mnot in project\033[0m)" >&2
    fi
    printf "\033[0m" >&2
    
    local display_dir="${DC_ORO_APPDIR:-$(pwd)}"
    if [[ -z "${DC_ORO_NAME:-}" ]]; then
      display_dir="-"
    fi
    if [[ "$display_dir" == "-" ]]; then
      echo -e "Current Directory: \033[90m-\033[0m" >&2
    else
      echo -e "Current Directory: $display_dir\033[0m" >&2
    fi
    printf "\033[0m" >&2
    
    if [[ -n "${VERBOSE:-}" ]]; then
      echo -e "VERBOSE mode: \033[32mON\033[0m" >&2
    else
      echo -e "VERBOSE mode: \033[90mOFF\033[0m" >&2
    fi
    printf "\033[0m" >&2
    echo "" >&2
    
    # Reset terminal attributes before prompt - CRITICAL to prevent text highlighting
    # Use multiple reset sequences to ensure all attributes are cleared (especially inverted colors)
    printf "\033[0m\033[27m\033[22m\033[23m\033[24m\033[25m" >&2
    tput sgr0 2>/dev/null || true
    printf "\033[0m\033[?25h" >&2
    tput sgr0 2>/dev/null || true
    stty sane 2>/dev/null || true
    echo -n "Use ↑↓ arrows to navigate, or type number [1-23], 'v' for VERBOSE, 'q' to quit: " >&2
    # Display input buffer if user is typing a number
    if [[ -n "$input_buf" ]]; then
      printf "%s" "$input_buf" >&2
    fi
    # Final reset after prompt to ensure clean state
    printf "\033[0m" >&2
  }
  
  # Function to display menu with selection highlight
  display_menu_with_selection() {
    local selected_option=$1
    local use_two_cols=$2
    local use_three_cols="${3:-false}"
    
    # Reset attributes before drawing
    printf "\033[0m" >&2
    
    # Define menu items with full text (will be truncated to 32 chars)
    local menu_items=(
      "List all environments"
      "Initialize environment"
      "Start environment"
      "Stop environment"
      "Delete environment"
      "Re-build/Re-download Images"
      "Run doctor"
      "Connect via SSH"
      "Connect via CLI"
      "Export database"
      "Import database"
      "Purge database"
      "Add/Manage domains"
      "Configure application URL"
      "Show environment variables"
      "Clear cache"
      "Reindex search"
      "Platform update"
      "Install with demo"
      "Install without demo"
      "Install dependencies"
      "Start proxy"
      "Stop proxy"
    )
    
    # Helper function to render a single cell
    render_cell() {
      local opt_num=$1
      local is_selected=$2
      local text=$(format_menu_item "$opt_num" "${menu_items[$((opt_num-1))]}")
      if [[ $is_selected -eq 1 ]]; then
        printf "  \033[7m%-32s\033[0m\033[27m" "$text" >&2
      else
        printf "  %-32s" "$text" >&2
      fi
    }
    
    # Group rendering functions - each renders items for its group
    # These can be called in different order/columns for different layouts
    
    render_group_environment_management() {
      local sel=$1
      render_cell 1 $((sel == 1))
      render_cell 2 $((sel == 2))
      render_cell 3 $((sel == 3))
      render_cell 4 $((sel == 4))
      render_cell 5 $((sel == 5))
      render_cell 6 $((sel == 6))
    }
    
    render_group_maintenance() {
      local sel=$1
      render_cell 7 $((sel == 7))
      render_cell 8 $((sel == 8))
      render_cell 9 $((sel == 9))
    }
    
    render_group_database() {
      local sel=$1
      render_cell 10 $((sel == 10))
      render_cell 11 $((sel == 11))
      render_cell 12 $((sel == 12))
    }
    
    render_group_configuration() {
      local sel=$1
      render_cell 13 $((sel == 13))
      render_cell 14 $((sel == 14))
      render_cell 15 $((sel == 15))
    }
    
    render_group_oro_maintenance() {
      local sel=$1
      render_cell 16 $((sel == 16))
      render_cell 17 $((sel == 17))
      render_cell 18 $((sel == 18))
      render_cell 19 $((sel == 19))
      render_cell 20 $((sel == 20))
      render_cell 21 $((sel == 21))
    }
    
    render_group_proxy() {
      local sel=$1
      render_cell 22 $((sel == 22))
      render_cell 23 $((sel == 23))
    }
    
    # Helper to get item from group by index
    get_group_item() {
      local group=$1
      local index=$2
      local sel=$3
      
      case "$group" in
        environment) render_cell $((1 + index)) $((sel == $((1 + index)))) ;;
        maintenance) render_cell $((7 + index)) $((sel == $((7 + index)))) ;;
        database) render_cell $((10 + index)) $((sel == $((10 + index)))) ;;
        configuration) render_cell $((13 + index)) $((sel == $((13 + index)))) ;;
        oro) render_cell $((16 + index)) $((sel == $((16 + index)))) ;;
        proxy) render_cell $((22 + index)) $((sel == $((22 + index)))) ;;
        *) printf "  %-32s" "" >&2 ;;
      esac
    }
    
    if [[ "$use_three_cols" == "true" ]]; then
      # Three column layout - each column renders its groups independently
      # All groups align by height with empty lines
      # Column 1: Environment Management (1-6) + Maintenance (7-9)
      # Column 2: Database (10-12) + Configuration (13-14)
      # Column 3: Oro Maintenance (15-20) + Proxy (21-22)
      
      local sel=$selected_option
      printf "\033[0m" >&2
      
      # Section 1: Environment (6) vs Database (3) vs Oro (6)
      # Max height: 6, so Database needs 3 empty lines
      
      # Headers
      printf "  \033[1;36m%-32s\033[0m  \033[1;35m%-32s\033[0m  \033[1;31m%-32s\033[0m\n" "Environment Management:" "Database:" "Oro Maintenance:" >&2
      printf "\033[0m" >&2
      
      # Rows 1-3: All three groups have items
      get_group_item environment 0 $sel; get_group_item database 0 $sel; get_group_item oro 0 $sel; echo "" >&2
      get_group_item environment 1 $sel; get_group_item database 1 $sel; get_group_item oro 1 $sel; echo "" >&2
      get_group_item environment 2 $sel; get_group_item database 2 $sel; get_group_item oro 2 $sel; echo "" >&2
      
      # Rows 4-6: Environment + Oro continue, Database is empty
      get_group_item environment 3 $sel; printf "  %-32s" "" >&2; get_group_item oro 3 $sel; echo "" >&2
      get_group_item environment 4 $sel; printf "  %-32s" "" >&2; get_group_item oro 4 $sel; echo "" >&2
      get_group_item environment 5 $sel; printf "  %-32s" "" >&2; get_group_item oro 5 $sel; echo "" >&2
      
      # Empty line between sections
      echo "" >&2
      
      # Section 2: Maintenance (3) vs Configuration (3) vs Proxy (2)
      # Max height: 3, so Proxy needs 1 empty line
      
      # Headers
      printf "  \033[1;32m%-32s\033[0m  \033[1;33m%-32s\033[0m  \033[1;37m%-32s\033[0m\n" "Maintenance:" "Configuration:" "Proxy:" >&2
      printf "\033[0m" >&2
      
      # Rows 1-2: All three groups have items
      get_group_item maintenance 0 $sel; get_group_item configuration 0 $sel; get_group_item proxy 0 $sel; echo "" >&2
      get_group_item maintenance 1 $sel; get_group_item configuration 1 $sel; get_group_item proxy 1 $sel; echo "" >&2
      
      # Row 3: Maintenance and Configuration have items, Proxy is empty
      get_group_item maintenance 2 $sel; get_group_item configuration 2 $sel; printf "  %-32s" "" >&2; echo "" >&2
      printf "\033[0m" >&2
    elif [[ "$use_two_cols" == "true" ]]; then
      # Two column layout using group functions
      # Pairs: Environment+Maintenance, Database+Configuration, Oro+Proxy
      
      local sel=$selected_option
      printf "\033[0m" >&2
      
      # Section 1: Environment Management + Maintenance
      printf "  \033[1;36m%-32s\033[0m  \033[1;32m%-32s\033[0m\n" "Environment Management:" "Maintenance:" >&2
      printf "\033[0m" >&2
      
      # Environment has 6 items, Maintenance has 3
      get_group_item environment 0 $sel; get_group_item maintenance 0 $sel; echo "" >&2
      get_group_item environment 1 $sel; get_group_item maintenance 1 $sel; echo "" >&2
      get_group_item environment 2 $sel; get_group_item maintenance 2 $sel; echo "" >&2
      get_group_item environment 3 $sel; printf "  %-32s" "" >&2; echo "" >&2
      get_group_item environment 4 $sel; printf "  %-32s" "" >&2; echo "" >&2
      get_group_item environment 5 $sel; printf "  %-32s" "" >&2; echo "" >&2
      
      # Section 2: Database + Configuration
      echo "" >&2
      printf "  \033[1;35m%-32s\033[0m  \033[1;33m%-32s\033[0m\n" "Database:" "Configuration:" >&2
      printf "\033[0m" >&2
      
      # Database has 3 items, Configuration has 3
      get_group_item database 0 $sel; get_group_item configuration 0 $sel; echo "" >&2
      get_group_item database 1 $sel; get_group_item configuration 1 $sel; echo "" >&2
      get_group_item database 2 $sel; get_group_item configuration 2 $sel; echo "" >&2
      
      # Section 3: Oro Maintenance + Proxy
      echo "" >&2
      printf "  \033[1;31m%-32s\033[0m  \033[1;37m%-32s\033[0m\n" "Oro Maintenance:" "Proxy:" >&2
      printf "\033[0m" >&2
      
      # Oro has 6 items, Proxy has 2
      get_group_item oro 0 $sel; get_group_item proxy 0 $sel; echo "" >&2
      get_group_item oro 1 $sel; get_group_item proxy 1 $sel; echo "" >&2
      get_group_item oro 2 $sel; printf "  %-32s" "" >&2; echo "" >&2
      get_group_item oro 3 $sel; printf "  %-32s" "" >&2; echo "" >&2
      get_group_item oro 4 $sel; printf "  %-32s" "" >&2; echo "" >&2
      get_group_item oro 5 $sel; printf "  %-32s" "" >&2; echo "" >&2
      printf "\033[0m" >&2
    else
      # Single column layout
      printf "\033[0m" >&2
      echo -e "\033[1;36mEnvironment Management:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 1 $((selected_option == 1)) "List all environments"
      render_menu_option 2 $((selected_option == 2)) "Initialize environment"
      render_menu_option 3 $((selected_option == 3)) "Start environment"
      render_menu_option 4 $((selected_option == 4)) "Stop environment"
      render_menu_option 5 $((selected_option == 5)) "Delete environment"
      render_menu_option 6 $((selected_option == 6)) "Re-build/Re-download Images"
      echo "" >&2
      printf "\033[0m" >&2
      echo -e "\033[1;32mMaintenance:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 7 $((selected_option == 7)) "Run doctor"
      render_menu_option 8 $((selected_option == 8)) "Connect via SSH"
      render_menu_option 9 $((selected_option == 9)) "Connect via CLI"
      echo "" >&2
      printf "\033[0m" >&2
      echo -e "\033[1;35mDatabase:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 10 $((selected_option == 10)) "Export database"
      render_menu_option 11 $((selected_option == 11)) "Import database"
      render_menu_option 12 $((selected_option == 12)) "Purge database"
      echo "" >&2
      printf "\033[0m" >&2
      echo -e "\033[1;33mConfiguration:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 13 $((selected_option == 13)) "Add/Manage domains"
      render_menu_option 14 $((selected_option == 14)) "Configure application URL"
      render_menu_option 15 $((selected_option == 15)) "Show environment variables"
      echo "" >&2
      printf "\033[0m" >&2
      echo -e "\033[1;31mOro Maintenance:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 16 $((selected_option == 16)) "Clear cache"
      render_menu_option 17 $((selected_option == 17)) "Reindex search"
      render_menu_option 18 $((selected_option == 18)) "Platform update"
      render_menu_option 19 $((selected_option == 19)) "Install with demo"
      render_menu_option 20 $((selected_option == 20)) "Install without demo"
      render_menu_option 21 $((selected_option == 21)) "Install dependencies"
      echo "" >&2
      printf "\033[0m" >&2
      echo -e "\033[1;37mProxy:\033[0m" >&2
      printf "\033[0m" >&2
      render_menu_option 22 $((selected_option == 22)) "Start proxy"
      render_menu_option 23 $((selected_option == 23)) "Stop proxy"
      printf "\033[0m" >&2
    fi
    
    # CRITICAL: Reset all attributes after drawing menu to prevent text highlighting
    # Use multiple reset sequences to ensure all attributes are cleared (especially inverted colors)
    printf "\033[0m\033[27m\033[22m\033[23m\033[24m\033[25m" >&2
    tput sgr0 2>/dev/null || true
    # Force reset one more time
    printf "\033[0m" >&2
    tput sgr0 2>/dev/null || true
  }
  
  # Variable to store user input for display
  local input_buffer=""
  
  # Initial display with selection
  redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
  
  # Enable raw input mode for arrow keys (without time 0 to make read blocking)
  stty -echo -icanon min 1 2>/dev/null || true
  
  # Read input with arrow key support
  while true; do
    local key=""
    # Read single character (waits for input - blocking)
    if ! read -rsn1 key 2>/dev/null; then
      # If read fails (EOF or error), break loop
      break
    fi
    
    # Handle empty input as Enter (in raw mode, Enter may be empty)
    if [[ -z "$key" ]]; then
      choice=$selected
      break
    fi
    
    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\033' ]]; then
      read -rsn1 -t 0.1 tmp 2>/dev/null
      if [[ "$tmp" == "[" ]]; then
        read -rsn1 -t 0.1 tmp 2>/dev/null
        case "$tmp" in
          A) # Up arrow
            if [[ $selected -gt 1 ]]; then
              ((selected--)) || true
              input_buffer=""  # Clear input buffer when using arrows
              redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
            fi
            ;;
          B) # Down arrow
            if [[ $selected -lt $total_options ]]; then
              ((selected++)) || true
              input_buffer=""  # Clear input buffer when using arrows
              redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
            fi
            ;;
        esac
      fi
    # Handle Enter key
    elif [[ "$key" == $'\n' ]] || [[ "$key" == $'\r' ]]; then
      choice=$selected
      break
    # Handle Backspace/Delete for number input
    elif [[ "$key" == $'\177' ]] || [[ "$key" == $'\b' ]] || [[ "$key" == $'\x7f' ]]; then
      # Clear input buffer if user presses backspace
      if [[ -n "$input_buffer" ]]; then
        input_buffer=""
        redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
      fi
      continue
    # Filter: only allow Latin letters and digits
    elif [[ ! "$key" =~ ^[a-zA-Z0-9]$ ]]; then
      # Ignore invalid characters (non-Latin, non-digit)
      continue
    # Handle direct number input
    # Always wait for Enter - no immediate selection
    elif [[ "$key" =~ ^[0-9]$ ]]; then
      # Add first digit to input buffer
      input_buffer="$key"
      local num_input="$key"
      # Try to read second digit if available (for 10-21)
      # Use timeout to check if user is typing two-digit number
      # But NEVER select immediately - always wait for explicit Enter
      if read -rsn1 -t 0.6 second_digit 2>/dev/null; then
        # Filter: only allow digits for second character (for two-digit numbers)
        if [[ "$second_digit" =~ ^[0-9]$ ]]; then
          # Second digit entered - add to buffer and combine them
          input_buffer="${key}${second_digit}"
          num_input="${key}${second_digit}"
        # If non-digit character (including non-Latin), ignore silently and continue with single digit
        # This ensures only valid digits are accepted for two-digit numbers
        fi
      fi
      # Validate number and update selection (always wait for Enter in next iteration)
      if [[ "$num_input" =~ ^[1-9]$ ]] || [[ "$num_input" =~ ^1[0-9]$ ]] || [[ "$num_input" == "20" ]] || [[ "$num_input" == "21" ]] || [[ "$num_input" == "22" ]] || [[ "$num_input" == "23" ]]; then
        # Update selected option to match input, wait for Enter to confirm
        selected=$num_input
        redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
        # Continue loop to wait for Enter - NEVER break here
      else
        # Invalid number - clear buffer and redraw
        input_buffer=""
        redraw_menu_screen $selected $use_two_columns "$input_buffer" "$use_three_columns" "$status_display" || true
      fi
    # Handle 'v' for VERBOSE toggle
    elif [[ "$key" == "v" ]] || [[ "$key" == "V" ]]; then
      stty echo icanon 2>/dev/null || true
      echo "" >&2
      if [[ -n "${VERBOSE:-}" ]]; then
        unset VERBOSE
        msg_ok "VERBOSE mode disabled" >&2
      else
        export VERBOSE=1
        msg_ok "VERBOSE mode enabled" >&2
      fi
      sleep 0.5
      show_interactive_menu
      return
    # Handle 'q' to quit
    elif [[ "$key" == "q" ]] || [[ "$key" == "Q" ]]; then
      stty echo icanon 2>/dev/null || true
      echo "" >&2
      msg_info "Goodbye!"
      exit 0
    fi
  done
  
  # Restore terminal settings
  stty echo icanon 2>/dev/null || true
  stty sane 2>/dev/null || true
  
  # CRITICAL: Reset all terminal attributes before continuing to prevent text highlighting
  tput sgr0 2>/dev/null || printf "\033[0m" >&2
  printf "\033[0m\033[?25h" >&2
  
  # CRITICAL: Move to new line after Enter is pressed
  # This ensures that "==> Selected: ..." starts on a new line
  echo "" >&2
  
  # Choice should always be set when we exit the loop (via break with choice=$selected)
  # If choice is empty, something went wrong - restart menu
  if [[ -z "$choice" ]]; then
    msg_warning "No selection made, returning to menu" >&2
    sleep 1
    show_interactive_menu
    return
  fi
  
  case "$choice" in
    1)
      # Call list_environments function directly (already loaded from environment.sh)
      # This runs in the same shell, so exported variables are available
      local selected_path=""
      # Temporarily disable set -e to handle return code 2 (successful switch)
      set +e
      list_environments
      local switch_result=$?
      set -e
      selected_path="${ORODC_SELECTED_PATH:-}"
      unset ORODC_SELECTED_PATH
      
      if [[ $switch_result -eq 2 ]]; then
        if [[ -z "$selected_path" ]]; then
          msg_error "Environment switch failed: selected path is empty (exit code: 1)" >&2
          echo "" >&2
          echo -n "Press Enter to continue..." >&2
          read -r
          show_interactive_menu
          return
        fi
        # Environment was switched - change directory and reinitialize
        if [[ ! -d "$selected_path" ]]; then
          msg_error "Environment path does not exist: $selected_path (exit code: 1)" >&2
          echo "" >&2
          echo -n "Press Enter to continue..." >&2
          read -r
          show_interactive_menu
          return
        fi
        
        cd "$selected_path" || {
          msg_error "Failed to change directory to: $selected_path (exit code: 1)" >&2
          echo "" >&2
          echo -n "Press Enter to continue..." >&2
          read -r
          show_interactive_menu
          return
        }
        
        # Clear environment variables to force reinitialization
        unset ORODC_ENV_INITIALIZED
        unset DC_ORO_NAME
        unset DC_ORO_APPDIR
        unset DC_ORO_CONFIG_DIR
        
        # Reinitialize environment
        initialize_environment 2>/dev/null || true
        
        # Show success message
        echo "" >&2
        msg_ok "Switched to environment: $(basename "$selected_path") (exit code: 0)" >&2
        echo "" >&2
        
        # Restart menu
        show_interactive_menu
        return
      elif [[ $switch_result -eq 0 ]]; then
        # User cancelled or no switch needed - return to menu immediately
        show_interactive_menu
        return
      else
        # Error occurred
        msg_error "List environments failed (exit code: $switch_result)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      ;;
    2)
      run_command_with_menu_return init
      ;;
    3)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return up -d
      ;;
    4)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return down
      ;;
    5)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      echo "" >&2
      msg_danger "This will DELETE ALL DATA including database, volumes, and configuration!"
      if confirm_yes_no "Continue?"; then
        run_command_with_menu_return purge
      else
        show_interactive_menu
      fi
      ;;
    6)
      run_command_with_menu_return image build
      ;;
    7)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return doctor
      ;;
    8)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return ssh
      ;;
    9)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return database cli bash
      ;;
    10)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return database export
      ;;
    11)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return database import
      ;;
    12)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return database purge
      ;;
    13)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return conf domains
      ;;
    14)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return conf url
      ;;
    15)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return env
      ;;
    16)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return cache clear
      ;;
    17)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return search reindex
      ;;
    18)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return platform-update
      ;;
    19)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return install
      ;;
    20)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return install --without-demo
      ;;
    21)
      if ! check_in_project; then
        msg_error "Not in project directory (exit code: 1)" >&2
        echo "" >&2
        echo -n "Press Enter to continue..." >&2
        read -r
        show_interactive_menu
        return
      fi
      run_command_with_menu_return composer install
      ;;
    22)
      run_command_with_menu_return proxy up -d
      ;;
    23)
      run_command_with_menu_return proxy down
      ;;
    v|V)
      if [[ -n "${VERBOSE:-}" ]]; then
        unset VERBOSE
        msg_ok "VERBOSE mode disabled" >&2
      else
        export VERBOSE=1
        msg_ok "VERBOSE mode enabled" >&2
      fi
      sleep 0.5
      show_interactive_menu
      ;;
    q|Q)
      msg_info "Goodbye!"
      exit 0
      ;;
    *)
      msg_warning "Invalid option"
      sleep 1
      show_interactive_menu
      ;;
  esac
}

# Call the menu
show_interactive_menu
