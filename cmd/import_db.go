package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
	"path/filepath"
)

var importDbCmd = &cobra.Command{
	Use:   "import-db [path to dump.sql[.gz]]",
	Short: "Import database dump into container",
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		dumpPath, err := filepath.Abs(args[0])
		if err != nil {
			fmt.Println("Failed to resolve path:", err)
			os.Exit(1)
		}

		fmt.Println("[orodc-go] Importing DB dump:", dumpPath)

		dumpBase := filepath.Base(dumpPath)
		schema := os.Getenv("DC_ORO_DATABASE_SCHEMA")
		user := os.Getenv("DC_ORO_DATABASE_USER")
		host := os.Getenv("DC_ORO_DATABASE_HOST")
		port := os.Getenv("DC_ORO_DATABASE_PORT")
		pass := os.Getenv("DC_ORO_DATABASE_PASSWORD")
		db := os.Getenv("DC_ORO_DATABASE_DBNAME")

		var importCmd string
		if schema == "pgsql" || schema == "postgres" || schema == "postgresql" {
			importCmd = fmt.Sprintf(`zcat /%s | sed -E 's/^\s*CREATE\s+FUNCTION/CREATE OR REPLACE FUNCTION/I' | PGPASSWORD=%s psql -h %s -p %s -U %s -d %s`, dumpBase, pass, host, port, user, db)

		} else if schema == "mysql" || schema == "mariadb" {
			importCmd = fmt.Sprintf(`zcat /%s | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/DEFINER=CURRENT_USER */' | MYSQL_PWD=%s mysql -h%s -P%s -u%s %s`, dumpBase, pass, host, port, user, db)

		} else {
			fmt.Println("Unsupported DB schema:", schema)
			os.Exit(1)
		}

		execCmd := exec.Command("docker", "compose", "run", "--rm", "-v", dumpPath+":"+"/"+dumpBase, "cli", "bash", "-c", importCmd)
		execCmd.Stdout = os.Stdout
		execCmd.Stderr = os.Stderr
		execCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(importDbCmd)
}
