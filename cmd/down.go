package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os/exec"
)

var downCmd = &cobra.Command{
	Use:   "down",
	Short: "Stop Oro Platform containers",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("[orodc-go] Stopping containers...")
		execCmd := exec.Command("docker", "compose", "down")
		execCmd.Stdout = cmd.OutOrStdout()
		execCmd.Stderr = cmd.ErrOrStderr()
		err := execCmd.Run()
		if err != nil {
			fmt.Println("Error while stopping containers:", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(downCmd)
}
