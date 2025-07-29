package config

import (
	"os"
	"path/filepath"
	"strings"
)

// GetVersion reads the version from the VERSION file
func GetVersion() string {
	// Try to find VERSION file in various locations
	locations := []string{
		"VERSION",                              // Current directory
		"../VERSION",                           // Parent directory
		"../../VERSION",                        // Two levels up
		"/opt/homebrew/share/orodc-go/VERSION", // Homebrew share (ARM)
		"/usr/local/share/orodc-go/VERSION",    // Homebrew share (Intel)
	}

	for _, location := range locations {
		if content, err := os.ReadFile(location); err == nil {
			version := strings.TrimSpace(string(content))
			if version != "" {
				return version
			}
		}
	}

	// Fallback version if file not found
	return "1.0.0-dev"
}

// GetVersionInfo returns detailed version information
func GetVersionInfo() map[string]string {
	version := GetVersion()

	// Try to get git commit if available (for development builds)
	gitCommit := "unknown"
	if content, err := os.ReadFile(".git/HEAD"); err == nil {
		ref := strings.TrimSpace(string(content))
		if strings.HasPrefix(ref, "ref: ") {
			// Read the commit from the ref
			refPath := strings.TrimPrefix(ref, "ref: ")
			if commitContent, err := os.ReadFile(filepath.Join(".git", refPath)); err == nil {
				gitCommit = strings.TrimSpace(string(commitContent))[:8] // Short commit
			}
		} else {
			gitCommit = ref[:8] // Direct commit reference
		}
	}

	return map[string]string{
		"version":   version,
		"gitCommit": gitCommit,
		"buildDate": "unknown", // Could be injected at build time
	}
}
