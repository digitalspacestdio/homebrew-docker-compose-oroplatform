package cmd

import (
	"github.com/spf13/cobra"
	"os"
	"os/exec"
)

var sshCmd = &cobra.Command{
	Use:   "ssh",
	Short: "SSH into the CLI container",
	Run: func(cmd *cobra.Command, args []string) {
		sshCmd := exec.Command("docker", "compose", "exec", "cli", "bash")
		sshCmd.Stdin = os.Stdin
		sshCmd.Stdout = os.Stdout
		sshCmd.Stderr = os.Stderr
		sshCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(sshCmd)
}
