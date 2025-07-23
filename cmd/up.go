package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start the Oro environment (docker-compose up)",
	Args:  cobra.ArbitraryArgs,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Starting Oro environment...")

		dockerArgs := append([]string{"compose", "up"}, args...)
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
