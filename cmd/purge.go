package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
)

var purgeCmd = &cobra.Command{
	Use:   "purge",
	Short: "Stop and remove all containers, volumes and config",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("[orodc-go] Purging environment...")
		exec.Command("docker", "compose", "down", "-v").Run()

		// Remove volume
		volName := os.Getenv("DC_ORO_NAME") + "_appcode"
		exec.Command("docker", "volume", "rm", "-f", volName).Run()

		// Remove config dir
		confDir := os.Getenv("DC_ORO_CONFIG_DIR")
		if confDir != "" {
			os.RemoveAll(confDir)
			fmt.Println("[orodc-go] Removed config dir:", confDir)
		}
	},
}

func init() {
	rootCmd.AddCommand(purgeCmd)
}
