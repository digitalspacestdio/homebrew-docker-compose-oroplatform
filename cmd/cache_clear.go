package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os/exec"
)

var cacheClearCmd = &cobra.Command{
	Use:   "cache-clear",
	Short: "Clear OroPlatform cache",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("[orodc-go] Clearing cache...")
		exec.Command("docker", "compose", "run", "--rm", "cli", "bash", "-c", "rm -rf var/cache/*").Run()
	},
}

func init() {
	rootCmd.AddCommand(cacheClearCmd)
}
