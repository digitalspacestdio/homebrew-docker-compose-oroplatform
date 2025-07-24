package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start the Oro environment (docker-compose up)",
	Args:  cobra.ArbitraryArgs,
	Run: func(cmd *cobra.Command, args []string) {
		projectDir, err := os.Getwd()
		if err != nil {
			fmt.Fprintf(os.Stderr, "❌ Failed to get current directory: %v\n", err)
			os.Exit(1)
		}

		projectName := filepath.Base(projectDir)
		configDir := filepath.Join(os.Getenv("HOME"), ".orodc", projectName)

		// Copy compose/ from Homebrew pkgshare to configDir (only if not exists)
		composeSource := "/opt/homebrew/share/orodc-go/compose" // change if on Intel
		if _, err := os.Stat(configDir); os.IsNotExist(err) {
			fmt.Printf("📦 Copying compose/ files to: %s\n", configDir)
			if err := os.MkdirAll(configDir, 0755); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to create config dir: %v\n", err)
				os.Exit(1)
			}
			copyCmd := exec.Command("rsync", "-a", composeSource+"/", configDir+"/")
			copyCmd.Stdout = os.Stdout
			copyCmd.Stderr = os.Stderr
			if err := copyCmd.Run(); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to copy compose files: %v\n", err)
				os.Exit(1)
			}
		}

		// Build docker compose args
		composeFiles := []string{
			"-f", filepath.Join(configDir, "docker-compose.yml"),
			"-f", filepath.Join(configDir, "docker-compose-default.yml"),
			"-f", filepath.Join(configDir, "docker-compose-pgsql.yml"),
		}
		dockerArgs := append([]string{"compose"}, composeFiles...)
		dockerArgs = append(dockerArgs, "up")
		dockerArgs = append(dockerArgs, args...)

		fmt.Println("🐳 Running:", "docker", dockerArgs)

		composeCmd := exec.Command("docker", dockerArgs...)
		composeCmd.Stdout = os.Stdout
		composeCmd.Stderr = os.Stderr

		if err := composeCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Failed to start docker-compose: %v\n", err)
			os.Exit(1)
		}

		fmt.Println("✅ Oro environment is up!")
	},
}

func init() {
	rootCmd.AddCommand(upCmd)
}
