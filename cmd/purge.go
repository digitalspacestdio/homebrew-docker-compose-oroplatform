package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var purgeCmd = &cobra.Command{
	Use:   "purge",
	Short: "Stop and remove all containers, volumes and config",
	Long: `Stop and remove all containers, volumes, and configuration files.

This command will:
- Stop and remove all Docker containers and volumes
- Terminate Mutagen sync sessions (if used)
- Remove the appcode Docker volume
- Delete the project configuration directory

This is a destructive operation that cannot be undone.`,
	Run: func(cmd *cobra.Command, args []string) {
		runPurge()
	},
}

func runPurge() {
	fmt.Println("🧹 Purging OroPlatform environment...")

	// Setup environment to get proper project variables
	_, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	projectName := os.Getenv("DC_ORO_NAME")
	configDir := os.Getenv("DC_ORO_CONFIG_DIR")
	mode := os.Getenv("DC_ORO_MODE")

	// Terminate Mutagen sync session if in mutagen mode (like bash script)
	if mode == "mutagen" {
		terminateMutagenSync(projectName)
	}

	// Stop and remove containers with volumes (like bash script)
	fmt.Println("🐳 Stopping and removing containers...")
	composeFile := filepath.Join(configDir, "compose.yml")

	if _, err := os.Stat(composeFile); err == nil {
		// Use cached compose.yml if it exists (like bash script)
		fmt.Printf("📄 Using cached compose file: %s\n", composeFile)
		downCmd := exec.Command("docker", "compose", "-f", composeFile, "down", "-v")
		downCmd.Stdout = os.Stdout
		downCmd.Stderr = os.Stderr
		if err := downCmd.Run(); err != nil {
			fmt.Printf("⚠️ Warning: Failed to run docker compose down: %v\n", err)
		}
	} else {
		// Setup fresh compose args and run down (like bash script fallback)
		composeArgs, err := config.SetupEnvironment()
		if err == nil {
			dockerArgs := append(composeArgs, "down", "-v")
			downCmd := exec.Command("docker", dockerArgs...)
			downCmd.Stdout = os.Stdout
			downCmd.Stderr = os.Stderr
			if err := downCmd.Run(); err != nil {
				fmt.Printf("⚠️ Warning: Failed to run docker compose down: %v\n", err)
			}
		}
	}

	// Remove appcode volume if it exists (like bash script)
	removeAppcodeVolume(projectName)

	// Remove configuration directory (like bash script)
	if configDir != "" && configDir != "/" {
		if _, err := os.Stat(configDir); err == nil {
			fmt.Printf("🗂️ Removing config directory: %s\n", configDir)
			if err := os.RemoveAll(configDir); err != nil {
				fmt.Printf("⚠️ Warning: Failed to remove config directory: %v\n", err)
			} else {
				fmt.Printf("✅ Config directory removed\n")
			}
		}
	}

	fmt.Println("✅ Purge completed!")
}

// terminateMutagenSync terminates the mutagen sync session (like bash script)
func terminateMutagenSync(projectName string) {
	// Generate session name like bash script does
	sessionName := strings.ToLower(projectName + "-appcode")
	sessionName = strings.ReplaceAll(sessionName, "_", "-")
	// Replace any non-alphanumeric characters with hyphens
	var result strings.Builder
	for _, r := range sessionName {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			result.WriteRune(r)
		} else {
			result.WriteRune('-')
		}
	}
	sessionName = result.String()

	fmt.Printf("🔄 Checking for Mutagen sync session: %s\n", sessionName)

	// Check if mutagen session exists
	listCmd := exec.Command("mutagen", "sync", "list")
	output, err := listCmd.Output()
	if err != nil {
		// Mutagen not available or no sessions
		return
	}

	if strings.Contains(string(output), "Name: "+sessionName) {
		fmt.Printf("🛑 Terminating Mutagen sync session: %s\n", sessionName)
		terminateCmd := exec.Command("mutagen", "sync", "terminate", sessionName)
		terminateCmd.Stdout = os.Stdout
		terminateCmd.Stderr = os.Stderr
		if err := terminateCmd.Run(); err != nil {
			fmt.Printf("⚠️ Warning: Failed to terminate Mutagen session: %v\n", err)
		} else {
			fmt.Printf("✅ Mutagen session terminated\n")
		}
	}
}

// removeAppcodeVolume removes the appcode volume if it exists (like bash script)
func removeAppcodeVolume(projectName string) {
	volumeName := projectName + "_appcode"

	fmt.Printf("📦 Checking for Docker volume: %s\n", volumeName)

	// Check if volume exists (like bash script logic)
	listCmd := exec.Command("docker", "volume", "ls", "--format", "{{.Name}}")
	output, err := listCmd.Output()
	if err != nil {
		fmt.Printf("⚠️ Warning: Failed to list Docker volumes: %v\n", err)
		return
	}

	volumes := strings.Split(string(output), "\n")
	for _, volume := range volumes {
		if strings.TrimSpace(volume) == volumeName {
			fmt.Printf("🗑️ Removing Docker volume: %s\n", volumeName)
			rmCmd := exec.Command("docker", "volume", "rm", volumeName)
			rmCmd.Stdout = os.Stdout
			rmCmd.Stderr = os.Stderr
			if err := rmCmd.Run(); err != nil {
				fmt.Printf("⚠️ Warning: Failed to remove volume: %v\n", err)
			} else {
				fmt.Printf("✅ Docker volume removed\n")
			}
			return
		}
	}

	fmt.Printf("ℹ️ Docker volume '%s' not found\n", volumeName)
}

func init() {
	rootCmd.AddCommand(purgeCmd)
}
