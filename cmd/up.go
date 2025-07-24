package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start the Oro environment (docker-compose up)",
	Args:  cobra.ArbitraryArgs,
	Run: func(cmd *cobra.Command, args []string) {
		// Setup environment and get compose file paths
		composeArgs, err := config.SetupEnvironment()
		if err != nil {
			fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
			os.Exit(1)
		}

		dockerArgs := append(composeArgs, "up")
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
