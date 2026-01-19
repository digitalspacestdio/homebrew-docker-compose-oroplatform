#!/bin/bash
# Port Manager Library
# Wrapper for orodc-find_free_port utility

# Find and export all service ports in batch mode
# Usage: find_and_export_ports "project_name" "config_dir"
find_and_export_ports() {
  local project_name="$1"
  local config_dir="$2"

  debug_log "find_and_export_ports: START - project=${project_name}, config_dir=${config_dir}"
  debug_log "find_and_export_ports: START - DC_ORO_PORT_PREFIX=${DC_ORO_PORT_PREFIX:-not set}"
  debug_log "find_and_export_ports: START - SCRIPT_DIR=${SCRIPT_DIR:-not set}, DIR=${DIR:-not set}"

  # Always set ports with prefix first (base ports)
  export DC_ORO_PORT_NGINX="${DC_ORO_PORT_NGINX:-${DC_ORO_PORT_PREFIX}80}"
  export DC_ORO_PORT_XHGUI="${DC_ORO_PORT_XHGUI:-${DC_ORO_PORT_PREFIX}81}"
  export DC_ORO_PORT_MYSQL="${DC_ORO_PORT_MYSQL:-${DC_ORO_PORT_PREFIX}06}"
  export DC_ORO_PORT_PGSQL="${DC_ORO_PORT_PGSQL:-${DC_ORO_PORT_PREFIX}32}"
  export DC_ORO_PORT_SEARCH="${DC_ORO_PORT_SEARCH:-${DC_ORO_PORT_PREFIX}92}"
  export DC_ORO_PORT_MQ="${DC_ORO_PORT_MQ:-${DC_ORO_PORT_PREFIX}72}"
  export DC_ORO_PORT_REDIS="${DC_ORO_PORT_REDIS:-${DC_ORO_PORT_PREFIX}79}"
  export DC_ORO_PORT_MAIL_WEBGUI="${DC_ORO_PORT_MAIL_WEBGUI:-${DC_ORO_PORT_PREFIX}25}"
  export DC_ORO_PORT_SSH="${DC_ORO_PORT_SSH:-${DC_ORO_PORT_PREFIX}22}"
  debug_log "find_and_export_ports: STEP 1 - Base ports set with prefix"

  # Find orodc-find_free_port utility
  # It's installed in libexec/ directory (same level as libexec/orodc/)
  # In bin/orodc, SCRIPT_DIR points to libexec/, so orodc-find_free_port is at SCRIPT_DIR/orodc-find_free_port
  local find_port_bin=""
  
  # Try PATH first
  debug_log "find_and_export_ports: STEP 2 - Checking PATH for orodc-find_free_port"
  if command -v orodc-find_free_port >/dev/null 2>&1; then
    find_port_bin=$(command -v orodc-find_free_port)
    debug_log "find_and_export_ports: STEP 2 - FOUND in PATH: $find_port_bin"
  else
    debug_log "find_and_export_ports: STEP 2 - NOT found in PATH"
    # Try using SCRIPT_DIR from bin/orodc (points to libexec/)
    # This is exported by bin/orodc before sourcing libraries
    debug_log "find_and_export_ports: STEP 3 - Checking SCRIPT_DIR=${SCRIPT_DIR:-not set}"
    if [[ -n "${SCRIPT_DIR:-}" ]]; then
      debug_log "find_and_export_ports: STEP 3 - SCRIPT_DIR exists, checking ${SCRIPT_DIR}/orodc-find_free_port"
      if [[ -f "${SCRIPT_DIR}/orodc-find_free_port" ]]; then
        debug_log "find_and_export_ports: STEP 3 - File exists, checking executable bit"
        if [[ -x "${SCRIPT_DIR}/orodc-find_free_port" ]]; then
          find_port_bin="${SCRIPT_DIR}/orodc-find_free_port"
          debug_log "find_and_export_ports: STEP 3 - FOUND via SCRIPT_DIR: $find_port_bin"
        else
          debug_log "find_and_export_ports: STEP 3 - File exists but not executable"
        fi
      else
        debug_log "find_and_export_ports: STEP 3 - File does not exist at ${SCRIPT_DIR}/orodc-find_free_port"
      fi
    else
      debug_log "find_and_export_ports: STEP 3 - SCRIPT_DIR not set"
    fi
    
    if [[ -z "$find_port_bin" ]]; then
      # Try using DIR variable from environment.sh (points to share/docker-compose-oroplatform)
      # DIR is at <prefix>/share/docker-compose-oroplatform, libexec is at <prefix>/libexec/
      debug_log "find_and_export_ports: STEP 4 - Checking DIR=${DIR:-not set}"
      if [[ -n "${DIR:-}" ]]; then
        # DIR = <prefix>/share/docker-compose-oroplatform
        # libexec = <prefix>/libexec/
        # So: $(dirname "$DIR") = <prefix>/share, then ../libexec/ = <prefix>/libexec/
        local prefix_dir="$(dirname "$(dirname "$DIR")")"
        local candidate="${prefix_dir}/libexec/orodc-find_free_port"
        debug_log "find_and_export_ports: STEP 4 - DIR-based candidate: $candidate (prefix_dir=${prefix_dir})"
        if [[ -f "$candidate" ]]; then
          debug_log "find_and_export_ports: STEP 4 - File exists, checking executable bit"
          if [[ -x "$candidate" ]]; then
            find_port_bin="$candidate"
            debug_log "find_and_export_ports: STEP 4 - FOUND via DIR: $find_port_bin"
          else
            debug_log "find_and_export_ports: STEP 4 - File exists but not executable"
          fi
        else
          debug_log "find_and_export_ports: STEP 4 - File does not exist at $candidate"
        fi
      else
        debug_log "find_and_export_ports: STEP 4 - DIR not set"
      fi
      
      # Fallback: try relative to current script (for development/testing)
      if [[ -z "$find_port_bin" ]]; then
        local script_file="${BASH_SOURCE[0]}"
        if [[ -n "$script_file" ]] && [[ -f "$script_file" ]]; then
          local script_dir="$(cd "$(dirname "$script_file")" && pwd)"
          local libexec_dir="$(dirname "$(dirname "$script_dir")")"
          local candidate="${libexec_dir}/orodc-find_free_port"
          debug_log "find_and_export_ports: checking script-relative path: $candidate (script_dir=$script_dir)"
          
          if [[ -x "$candidate" ]]; then
            find_port_bin="$candidate"
            debug_log "find_and_export_ports: found orodc-find_free_port via script path: $find_port_bin"
          fi
        fi
      fi
    fi
  fi

  if [[ -z "$find_port_bin" ]] || [[ ! -x "$find_port_bin" ]]; then
    debug_log "find_and_export_ports: orodc-find_free_port not found (checked PATH, SCRIPT_DIR=${SCRIPT_DIR:-not set}, DIR=${DIR:-not set}), using prefix-based ports"
    debug_log "find_and_export_ports: SCRIPT_DIR check: ${SCRIPT_DIR:-not set}, file exists: $([[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "${SCRIPT_DIR}/orodc-find_free_port" ]] && echo "yes" || echo "no")"
    return 0
  fi

  debug_log "find_and_export_ports: project=${project_name}, config_dir=${config_dir}, prefix=${DC_ORO_PORT_PREFIX}, bin=${find_port_bin}"

  # Use batch port resolution for better performance
  debug_log "find_and_export_ports: calling orodc-find_free_port --batch"
  BATCH_PORTS=$("$find_port_bin" --batch "${project_name}" "$config_dir" \
    nginx "${DC_ORO_PORT_PREFIX}80" \
    xhgui "${DC_ORO_PORT_PREFIX}81" \
    database "${DC_ORO_PORT_PREFIX}06" \
    database "${DC_ORO_PORT_PREFIX}32" \
    search "${DC_ORO_PORT_PREFIX}92" \
    mq "${DC_ORO_PORT_PREFIX}72" \
    redis "${DC_ORO_PORT_PREFIX}79" \
    mail "${DC_ORO_PORT_PREFIX}25" \
    ssh "${DC_ORO_PORT_PREFIX}22" 2>&1)
  
  local exit_code=$?
  debug_log "find_and_export_ports: orodc-find_free_port exit_code=$exit_code"
  
  if [[ $exit_code -ne 0 ]] || [[ -z "$BATCH_PORTS" ]]; then
    debug_log "find_and_export_ports: orodc-find_free_port failed, using prefix-based ports"
    debug_log "find_and_export_ports: exit_code=$exit_code, output='$BATCH_PORTS'"
    return 0
  fi

  debug_log "find_and_export_ports: batch results='$BATCH_PORTS'"

  # Parse batch results and override with found free ports
  while IFS=':' read -r service port; do
    [[ -z "$service" ]] && continue
    [[ -z "$port" ]] && continue
    
    debug_log "find_and_export_ports: setting DC_ORO_PORT_${service^^}=$port"
    
    case "$service" in
      nginx)
        export DC_ORO_PORT_NGINX="$port"
        ;;
      xhgui)
        export DC_ORO_PORT_XHGUI="$port"
        ;;
      database)
        if [[ -z "$DC_ORO_PORT_MYSQL" ]] || [[ "$DC_ORO_PORT_MYSQL" == "${DC_ORO_PORT_PREFIX}06" ]]; then
          export DC_ORO_PORT_MYSQL="$port"
        else
          export DC_ORO_PORT_PGSQL="$port"
        fi
        ;;
      search)
        export DC_ORO_PORT_SEARCH="$port"
        ;;
      mq)
        export DC_ORO_PORT_MQ="$port"
        ;;
      redis)
        export DC_ORO_PORT_REDIS="$port"
        ;;
      mail)
        export DC_ORO_PORT_MAIL_WEBGUI="$port"
        ;;
      ssh)
        export DC_ORO_PORT_SSH="$port"
        ;;
    esac
  done <<< "$BATCH_PORTS"
  
  debug_log "find_and_export_ports: final ports - MQ=${DC_ORO_PORT_MQ}, SEARCH=${DC_ORO_PORT_SEARCH}, REDIS=${DC_ORO_PORT_REDIS}"
}

# Find a single port for a specific service
# Usage: find_single_port "project_name" "config_dir" "service_name" "default_port"
# Returns: port number
find_single_port() {
  local project_name="$1"
  local config_dir="$2"
  local service_name="$3"
  local default_port="$4"

  # Find orodc-find_free_port utility (same logic as find_and_export_ports)
  local find_port_bin=""
  
  if command -v orodc-find_free_port >/dev/null 2>&1; then
    find_port_bin=$(command -v orodc-find_free_port)
  elif [[ -n "${SCRIPT_DIR:-}" ]] && [[ -x "${SCRIPT_DIR}/orodc-find_free_port" ]]; then
    find_port_bin="${SCRIPT_DIR}/orodc-find_free_port"
  elif [[ -n "${DIR:-}" ]]; then
    local prefix_dir="$(dirname "$(dirname "$DIR")")"
    local candidate="${prefix_dir}/libexec/orodc-find_free_port"
    if [[ -x "$candidate" ]]; then
      find_port_bin="$candidate"
    fi
  else
    # Fallback: try relative to current script
    local script_file="${BASH_SOURCE[0]}"
    if [[ -n "$script_file" ]] && [[ -f "$script_file" ]]; then
      local script_dir="$(cd "$(dirname "$script_file")" && pwd)"
      local libexec_dir="$(dirname "$(dirname "$script_dir")")"
      local candidate="${libexec_dir}/orodc-find_free_port"
      
      if [[ -x "$candidate" ]]; then
        find_port_bin="$candidate"
      fi
    fi
  fi

  if [[ -z "$find_port_bin" ]] || [[ ! -x "$find_port_bin" ]]; then
    echo "$default_port"
    return 0
  fi

  "$find_port_bin" "$project_name" "$config_dir" "$service_name" "$default_port"
}
