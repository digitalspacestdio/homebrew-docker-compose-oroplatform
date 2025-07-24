package config

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func LoadEnvSafe(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "#") || len(line) == 0 {
			continue
		}
		if !strings.Contains(line, "=") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		key := strings.TrimSpace(parts[0])
		value := strings.Trim(strings.TrimSpace(parts[1]), `"'`)
		os.Setenv(key, value)
	}
	return nil
}

func SetupEnvironment() ([]string, error) {
	projectDir, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to get current directory: %v", err)
	}

	projectName := filepath.Base(projectDir)
	configDir := filepath.Join(os.Getenv("HOME"), ".orodc", projectName)

	// Copy compose/ from Homebrew pkgshare to configDir (only if not exists)
	composeSource := "/opt/homebrew/share/orodc-go/compose" // change if on Intel
	if _, err := os.Stat(configDir); os.IsNotExist(err) {
		fmt.Printf("📦 Copying compose/ files to: %s\n", configDir)
		if err := os.MkdirAll(configDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create config dir: %v", err)
		}
		copyCmd := exec.Command("rsync", "-a", composeSource+"/", configDir+"/")
		copyCmd.Stdout = os.Stdout
		copyCmd.Stderr = os.Stderr
		if err := copyCmd.Run(); err != nil {
			return nil, fmt.Errorf("failed to copy compose files: %v", err)
		}
	}

	// Build docker compose args
	composeFiles := []string{
		"compose",
		"-f", filepath.Join(configDir, "docker-compose.yml"),
		"-f", filepath.Join(configDir, "docker-compose-default.yml"),
		"-f", filepath.Join(configDir, "docker-compose-pgsql.yml"),
	}

	// Set required environment variables
	os.Setenv("DC_ORO_NAME", projectName)
	if os.Getenv("DC_ORO_APPDIR") == "" {
		os.Setenv("DC_ORO_APPDIR", projectDir)
	}

	return composeFiles, nil
}
