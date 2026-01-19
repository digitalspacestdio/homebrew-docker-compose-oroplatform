#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"
source "${SCRIPT_DIR}/lib/wizard.sh"

# Check if running in interactive mode
is_interactive() {
  # If called from interactive menu, always use interactive mode
  if [[ -n "${ORODC_IS_INTERACTIVE_MENU:-}" ]]; then
    return 0
  fi
  # Otherwise check if stdin/stdout are TTYs
  [ -t 0 ] && [ -t 1 ]
}


# Update .env.orodc file
update_env_file() {
  local key="$1"
  local value="$2"
  
  # Always use local project file (.env.orodc in project root)
  local env_file="${DC_ORO_APPDIR}/.env.orodc"
  
  if [[ ! -f "$env_file" ]]; then
    touch "$env_file"
  fi
  
  # Remove existing line if present
  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "/^${key}=/d" "$env_file"
    else
      sed -i "/^${key}=/d" "$env_file"
    fi
  fi
  
  # Add new line
  echo "${key}=${value}" >> "$env_file"
}

# Manage domains - interactive mode
manage_domains_interactive() {
  # Use local project file (.env.orodc in project root)
  local env_file="${DC_ORO_APPDIR}/.env.orodc"
  local current_hosts="${DC_ORO_EXTRA_HOSTS:-}"
  local domains=()
  
  # Load current domains from .env.orodc file if it exists
  # Always read from file to ensure we have the latest values, even if file was edited manually
  if [[ -f "$env_file" ]]; then
    local file_hosts=$(grep "^DC_ORO_EXTRA_HOSTS=" "$env_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
    if [[ -n "$file_hosts" ]]; then
      current_hosts="$file_hosts"
    fi
  fi
  
  # Parse current domains
  if [[ -n "$current_hosts" ]]; then
    IFS=',' read -ra domains <<< "$current_hosts"
  fi
  
  # Function to display domain list and handle input (for wizard)
  display_domain_list() {
    local input="${1:-}"
    
    if [[ -z "$input" ]]; then
      continue
    fi
    
    if [[ "$input" == "done" ]] || [[ "$input" == "q" ]]; then
      break
    fi
    
    if [[ "$input" =~ ^remove\ (.+)$ ]]; then
      # Remove domain
      local domain_to_remove="${BASH_REMATCH[1]}"
      domain_to_remove=$(echo "$domain_to_remove" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      
      local new_domains=()
      for domain in "${domains[@]}"; do
        domain=$(echo "$domain" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$domain" != "$domain_to_remove" ]] && [[ -n "$domain" ]]; then
          new_domains+=("$domain")
        fi
      done
      domains=("${new_domains[@]}")
      
      msg_ok "Removed domain: $domain_to_remove" >&2
    else
      # Add domain
      local new_domain
      new_domain=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      
      if [[ -z "$new_domain" ]]; then
        continue
      fi
      
      if [[ "$input" =~ ^remove\ (.+)$ ]]; then
        # Remove domain logic
        local remove_arg="${BASH_REMATCH[1]}"
        remove_arg=$(echo "$remove_arg" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        local domain_to_remove=""
        
        # Check if remove_arg is a number (remove by index)
        if [[ "$remove_arg" =~ ^[0-9]+$ ]]; then
          # Check if trying to remove default domain (0)
          if [[ "$remove_arg" == "0" ]]; then
            msg_warning "Cannot remove default domain (0) - it is immutable" >&2
            sleep 1
            return 2  # Redraw
          fi
          # Number 1 = index 0, number 2 = index 1, etc.
          local index=$((remove_arg - 1))
          if [[ $index -ge 0 ]] && [[ $index -lt ${#domains[@]} ]]; then
            domain_to_remove="${domains[$index]}"
            domain_to_remove=$(echo "$domain_to_remove" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          else
            msg_warning "Invalid domain number: $remove_arg" >&2
            sleep 1
            return 2  # Redraw
          fi
        else
          # Remove by domain name - check if trying to remove default domain
          local default_domain_name="${DC_ORO_NAME}.docker.local"
          if [[ "$remove_arg" == "$default_domain_name" ]] || [[ "$remove_arg" == "${DC_ORO_NAME}" ]]; then
            msg_warning "Cannot remove default domain - it is immutable" >&2
            sleep 1
            return 2  # Redraw
          fi
          domain_to_remove="$remove_arg"
        fi
        
        if [[ -z "$domain_to_remove" ]]; then
          return 2  # Redraw
        fi
        
        local new_domains=()
        local found=false
        for domain in "${domains[@]}"; do
          domain=$(echo "$domain" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ "$domain" == "$domain_to_remove" ]] && [[ "$found" == "false" ]]; then
            found=true
            # Skip this domain (remove it)
          elif [[ -n "$domain" ]]; then
            new_domains+=("$domain")
          fi
        done
        
        if [[ "$found" == "true" ]]; then
          domains=("${new_domains[@]}")
          msg_ok "Removed domain: $domain_to_remove" >&2
          sleep 1
        else
          msg_warning "Domain not found: $domain_to_remove" >&2
          sleep 1
        fi
        return 2  # Redraw
      else
        # Add domain
        # Input is already filtered at input level, just trim whitespace
        local new_domain=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -z "$new_domain" ]]; then
          return 2  # Redraw
        fi
        
        # Check if already exists
        local exists=false
        for domain in "${domains[@]}"; do
          domain=$(echo "$domain" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ "$domain" == "$new_domain" ]]; then
            exists=true
            break
          fi
        done
        
        if [[ "$exists" == "false" ]]; then
          domains+=("$new_domain")
          msg_ok "Added domain: $new_domain" >&2
          sleep 1
        else
          msg_warning "Domain already exists: $new_domain" >&2
          sleep 1
        fi
        return 2  # Redraw
      fi
    fi
    
    # Display current state (no input provided)
    echo "" >&2
    msg_highlight "Domain Management for: ${DC_ORO_NAME}" >&2
    echo "" >&2
    
    # Get default domain
    local default_domain="${DC_ORO_NAME}.docker.local"
    
    msg_info "Current domains:" >&2
    # Always show default domain first as 0) and immutable
    echo -e "  0) ${default_domain} \033[90m(default, immutable)\033[0m" >&2
    
    # Show extra domains if any
    if [[ ${#domains[@]} -gt 0 ]]; then
      local i=1
      for domain in "${domains[@]}"; do
        domain=$(echo "$domain" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -n "$domain" ]]; then
          # Check if domain is short (no dots) - add .docker.local suffix in display
          if [[ "$domain" != *.* ]]; then
            # Short domain - show with .docker.local suffix (suffix in dark gray)
            echo -e "  $i) ${domain}\033[90m.docker.local\033[0m" >&2
          else
            # Full hostname - show as-is
            echo "  $i) $domain" >&2
          fi
          i=$((i + 1))
        fi
      done
    fi
    
    echo "" >&2
    msg_info "Domain format:" >&2
    echo "  - Short names (e.g., 'api', 'admin') will automatically get '.docker.local' suffix" >&2
    echo "  - Full hostnames (e.g., 'api.example.com') will be used as-is" >&2
    echo "" >&2
    msg_info "Commands:" >&2
    echo "  - Add domain: enter domain name (e.g., 'api' or 'api.example.com')" >&2
    echo "  - Remove domain: 'remove <number>' or 'remove <domain>' (e.g., 'remove 1' or 'remove api')" >&2
    echo "  - Finish: 'done' or 'q'" >&2
    echo "" >&2
    
    return 0
  }
  
  # Use wizard_simple for domain management
  wizard_simple "Domain Management for: ${DC_ORO_NAME}" "display_domain_list" "Add domain (or 'remove <number|domain>' to delete, 'done' to finish): "
  
  # Update .env.orodc after wizard completes
  if [[ ${#domains[@]} -gt 0 ]]; then
    local domains_str
    domains_str=$(IFS=','; echo "${domains[*]}")
    update_env_file "DC_ORO_EXTRA_HOSTS" "$domains_str"
    msg_ok "Updated domains in .env.orodc" >&2
  else
    # Remove if empty
    if grep -q "^DC_ORO_EXTRA_HOSTS=" "$env_file" 2>/dev/null; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "/^DC_ORO_EXTRA_HOSTS=/d" "$env_file"
      else
        sed -i "/^DC_ORO_EXTRA_HOSTS=/d" "$env_file"
      fi
      msg_ok "Removed domains from .env.orodc" >&2
    fi
  fi
  
  return 0
}

# Manage domains - non-interactive mode
manage_domains_noninteractive() {
  local action="${1:-list}"
  shift || true
  
  local env_file="${DC_ORO_APPDIR}/.env.orodc"
  
  # Helper function to load current hosts from file
  # Always read from file to ensure we have the latest values, even if file was edited manually
  load_current_hosts() {
    local current_hosts="${DC_ORO_EXTRA_HOSTS:-}"
    # Load from .env.orodc file if it exists (file takes priority over environment variable)
    if [[ -f "$env_file" ]]; then
      local file_hosts=$(grep "^DC_ORO_EXTRA_HOSTS=" "$env_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
      if [[ -n "$file_hosts" ]]; then
        current_hosts="$file_hosts"
      fi
    fi
    echo "$current_hosts"
  }
  
  case "$action" in
    list)
      local current_hosts=$(load_current_hosts)
      if [[ -n "$current_hosts" ]]; then
        echo "$current_hosts" | tr ',' '\n'
      else
        echo ""
      fi
      ;;
    add)
      local domain="$1"
      if [[ -z "$domain" ]]; then
        msg_error "Domain name required"
        echo "" >&2
        msg_info "Usage: orodc conf domains add <domain>" >&2
        msg_info "Examples:" >&2
        echo "  orodc conf domains add api          # Short name → api.docker.local" >&2
        echo "  orodc conf domains add admin       # Short name → admin.docker.local" >&2
        echo "  orodc conf domains add api.example.com  # Full hostname → api.example.com" >&2
        exit 1
      fi
      
      local current_hosts=$(load_current_hosts)
      local domains=()
      
      if [[ -n "$current_hosts" ]]; then
        IFS=',' read -ra domains <<< "$current_hosts"
      fi
      
      # Check if already exists
      for existing in "${domains[@]}"; do
        existing=$(echo "$existing" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$existing" == "$domain" ]]; then
          msg_warning "Domain already exists: $domain"
          exit 0
        fi
      done
      
      domains+=("$domain")
      local domains_str
      domains_str=$(IFS=','; echo "${domains[*]}")
      update_env_file "DC_ORO_EXTRA_HOSTS" "$domains_str"
      msg_ok "Added domain: $domain"
      ;;
    remove)
      local domain="$1"
      if [[ -z "$domain" ]]; then
        msg_error "Domain name required"
        exit 1
      fi
      
      local current_hosts=$(load_current_hosts)
      local domains=()
      
      if [[ -n "$current_hosts" ]]; then
        IFS=',' read -ra domains <<< "$current_hosts"
      fi
      
      local new_domains=()
      local found=false
      for existing in "${domains[@]}"; do
        existing=$(echo "$existing" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$existing" != "$domain" ]] && [[ -n "$existing" ]]; then
          new_domains+=("$existing")
        else
          found=true
        fi
      done
      
      if [[ "$found" == "false" ]]; then
        msg_warning "Domain not found: $domain"
        exit 1
      fi
      
      if [[ ${#new_domains[@]} -gt 0 ]]; then
        local domains_str
        domains_str=$(IFS=','; echo "${new_domains[*]}")
        update_env_file "DC_ORO_EXTRA_HOSTS" "$domains_str"
      else
        # Remove DC_ORO_EXTRA_HOSTS from file if no domains left
        if grep -q "^DC_ORO_EXTRA_HOSTS=" "$env_file" 2>/dev/null; then
          if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/^DC_ORO_EXTRA_HOSTS=/d" "$env_file"
          else
            sed -i "/^DC_ORO_EXTRA_HOSTS=/d" "$env_file"
          fi
        fi
      fi
      
      msg_ok "Removed domain: $domain"
      ;;
    set)
      local domains_str="$1"
      if [[ -z "$domains_str" ]]; then
        msg_error "Domain list required"
        exit 1
      fi
      
      update_env_file "DC_ORO_EXTRA_HOSTS" "$domains_str"
      msg_ok "Set domains: $domains_str"
      ;;
    *)
      msg_error "Unknown action: $action"
      echo "" >&2
      msg_info "Available actions: list, add, remove, set" >&2
      echo "" >&2
      msg_info "Examples:" >&2
      echo "  orodc conf domains list                    # List all domains" >&2
      echo "  orodc conf domains add api                 # Add domain (short name → api.docker.local)" >&2
      echo "  orodc conf domains add api.example.com     # Add domain (full hostname)" >&2
      echo "  orodc conf domains remove api             # Remove domain" >&2
      echo "  orodc conf domains set \"api,admin,shop\"  # Set multiple domains" >&2
      exit 1
      ;;
  esac
}

# Configure URL - interactive mode
configure_url_interactive() {
  local current_url="${DC_ORO_URL:-https://${DC_ORO_NAME}.docker.local}"
  
  echo "" >&2
  msg_highlight "Configure Application URL for: ${DC_ORO_NAME}" >&2
  echo "" >&2
  msg_info "Current URL: $current_url" >&2
  echo "" >&2
  echo -n "Enter new URL [default: $current_url]: " >&2
  read -r new_url
  
  if [[ -z "$new_url" ]]; then
    new_url="$current_url"
  fi
  
  # Validate URL format
  if [[ ! "$new_url" =~ ^https?:// ]]; then
    msg_error "Invalid URL format. URL must start with http:// or https://"
    return 1
  fi
  
  update_env_file "DC_ORO_URL" "$new_url"
  msg_ok "Updated URL: $new_url" >&2
  return 0
}

# Configure URL - non-interactive mode
configure_url_noninteractive() {
  local url="$1"
  
  if [[ -z "$url" ]]; then
    # Show current URL
    echo "${DC_ORO_URL:-https://${DC_ORO_NAME}.docker.local}"
    return 0
  fi
  
  # Validate URL format
  if [[ ! "$url" =~ ^https?:// ]]; then
    msg_error "Invalid URL format. URL must start with http:// or https://"
    exit 1
  fi
  
  update_env_file "DC_ORO_URL" "$url"
  msg_ok "Updated URL: $url"
}

# Main function
main() {
  local subcommand="${1:-}"
  shift || true
  local exit_code=0
  
  if ! check_in_project; then
    exit 1
  fi
  
  set +e
  case "$subcommand" in
    domains)
      if is_interactive; then
        manage_domains_interactive
        exit_code=$?
      else
        manage_domains_noninteractive "$@"
        exit_code=$?
      fi
      ;;
    url)
      if is_interactive; then
        configure_url_interactive
        exit_code=$?
      else
        configure_url_noninteractive "$@"
        exit_code=$?
      fi
      ;;
    *)
      msg_error "Unknown configuration command: ${subcommand:-<none>}"
      echo "" >&2
      msg_info "Available commands:" >&2
      echo "  orodc conf domains [list|add|remove|set] [args...]" >&2
      echo "  orodc conf url [url]" >&2
      set -e
      exit 1
      ;;
  esac
  set -e
  exit $exit_code
}

main "$@"
