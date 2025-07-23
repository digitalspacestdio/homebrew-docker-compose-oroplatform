package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
)

var consoleCmd = &cobra.Command{
	Use:   "console [arguments]",
	Short: "Run arbitrary bin/console command inside the container",
	Args:  cobra.ArbitraryArgs,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("[orodc-go] Executing console command: bin/console", args)
		consoleArgs := append([]string{"compose", "run", "--rm", "cli", "php", "bin/console"}, args...)
		execCmd := exec.Command("docker", consoleArgs...)
		execCmd.Stdin = os.Stdin
		execCmd.Stdout = os.Stdout
		execCmd.Stderr = os.Stderr
		execCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(consoleCmd)
}
