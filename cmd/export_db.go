package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

var exportDbCmd = &cobra.Command{
	Use:   "export-db [output path]",
	Short: "Export database dump from container",
	Args:  cobra.MaximumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		timestamp := time.Now().Format("20060102-150405")
		defaultPath := fmt.Sprintf("dump-%s.sql.gz", timestamp)
		var outPath string
		if len(args) > 0 {
			outPath = args[0]
		} else {
			outPath = defaultPath
		}

		outPathAbs, err := filepath.Abs(outPath)
		if err != nil {
			fmt.Println("Failed to resolve output path:", err)
			os.Exit(1)
		}

		outBase := filepath.Base(outPathAbs)
		cmdStr := fmt.Sprintf(`PGPASSWORD=$DC_ORO_DATABASE_PASSWORD pg_dump -h $DC_ORO_DATABASE_HOST -p $DC_ORO_DATABASE_PORT -U $DC_ORO_DATABASE_USER -d $DC_ORO_DATABASE_DBNAME | gzip > /%s`, outBase)

		execCmd := exec.Command("docker", "compose", "run", "--rm", "-v", outPathAbs+":"+"/"+outBase, "cli", "bash", "-c", cmdStr)
		execCmd.Stdin = os.Stdin
		execCmd.Stdout = os.Stdout
		execCmd.Stderr = os.Stderr
		execCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(exportDbCmd)
}
