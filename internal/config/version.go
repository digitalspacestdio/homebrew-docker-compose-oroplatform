package config

import (
	"os"
	"path/filepath"
	"strings"
)

// GetVersion reads the version from the VERSION file
func GetVersion() string {
	// Get the directory where the binary is located
	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		// Try VERSION file relative to binary location
		versionPath := filepath.Join(execDir, "VERSION")
		if content, err := os.ReadFile(versionPath); err == nil {
			version := strings.TrimSpace(string(content))
			if version != "" {
				return version
			}
		}
	}

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
	return "0.7.24-dev"
}

// GetVersionInfo returns detailed version information
func GetVersionInfo() map[string]string {
	version := GetVersion()

	// Try to get git commit if available (for development builds)
	gitCommit := "unknown"

	// Try to find .git directory in various locations
	gitLocations := []string{
		".git/HEAD",
		"../.git/HEAD",
		"../../.git/HEAD",
	}

	for _, gitPath := range gitLocations {
		if content, err := os.ReadFile(gitPath); err == nil {
			ref := strings.TrimSpace(string(content))
			if strings.HasPrefix(ref, "ref: ") {
				// Read the commit from the ref
				refPath := strings.TrimPrefix(ref, "ref: ")
				gitDir := filepath.Dir(gitPath)
				if commitContent, err := os.ReadFile(filepath.Join(gitDir, refPath)); err == nil {
					gitCommit = strings.TrimSpace(string(commitContent))[:8] // Short commit
					break
				}
			} else {
				gitCommit = ref[:8] // Direct commit reference
				break
			}
		}
	}

	return map[string]string{
		"version":   version,
		"gitCommit": gitCommit,
		"buildDate": "unknown", // Could be injected at build time
	}
}
