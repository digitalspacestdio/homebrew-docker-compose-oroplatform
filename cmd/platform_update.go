package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os/exec"
)

var platformUpdateCmd = &cobra.Command{
	Use:   "platform-update",
	Short: "Run oro:platform:update inside the container",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("[orodc-go] Running oro:platform:update...")
		execCmd := exec.Command("docker", "compose", "run", "--rm", "cli", "php", "bin/console", "oro:platform:update", "--env=prod")
		execCmd.Stdout = cmd.OutOrStdout()
		execCmd.Stderr = cmd.ErrOrStderr()
		execCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(platformUpdateCmd)
}
