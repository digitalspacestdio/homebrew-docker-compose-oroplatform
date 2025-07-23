package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "orodc-go",
	Short: "OroDC CLI utility for Oro developer environments",
	Long:  `OroDC helps manage docker-based OroPlatform dev environments`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Use `orodc-go --help` to see available commands.")
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		os.Exit(1)
	}
}
