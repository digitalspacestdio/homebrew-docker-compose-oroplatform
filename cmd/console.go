package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var consoleCmd = &cobra.Command{
	Use:   "console [command...]",
	Short: "Run console commands inside the CLI container",
	Long: `Run console commands inside the OroPlatform CLI container.
	
Examples:
  orodc-go console cache:clear                    # Clear cache
  orodc-go console oro:user:list                  # List users  
  orodc-go console oro:platform:update --force   # Update platform`,
	Run: func(cmd *cobra.Command, args []string) {
		runConsoleCommand(args)
	},
}

var cliCmd = &cobra.Command{
	Use:   "cli",
	Short: "Open an interactive CLI container session",
	Long:  `Open an interactive bash session in the OroPlatform CLI container.`,
	Run: func(cmd *cobra.Command, args []string) {
		runCLISession()
	},
}

// Add individual command shortcuts
var composerCmd = &cobra.Command{
	Use:   "composer [args...]",
	Short: "Run composer commands",
	Run: func(cmd *cobra.Command, args []string) {
		runCommandInContainer("composer", args)
	},
}

var phpCmd = &cobra.Command{
	Use:   "php [args...]",
	Short: "Run PHP commands",
	Run: func(cmd *cobra.Command, args []string) {
		runCommandInContainer("php", args)
	},
}

var npmCmd = &cobra.Command{
	Use:   "npm [args...]",
	Short: "Run npm commands",
	Run: func(cmd *cobra.Command, args []string) {
		runCommandInContainer("npm", args)
	},
}

var nodeCmd = &cobra.Command{
	Use:   "node [args...]",
	Short: "Run node commands",
	Run: func(cmd *cobra.Command, args []string) {
		runCommandInContainer("node", args)
	},
}

var yarnCmd = &cobra.Command{
	Use:   "yarn [args...]",
	Short: "Run yarn commands",
	Run: func(cmd *cobra.Command, args []string) {
		runCommandInContainer("yarn", args)
	},
}

var bashCmd = &cobra.Command{
	Use:   "bash [args...]",
	Short: "Run bash commands",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			runCLISession()
		} else {
			runCommandInContainer("bash", []string{"-c", strings.Join(args, " ")})
		}
	},
}

// Add database commands
var mysqlCmd = &cobra.Command{
	Use:   "mysql",
	Short: "Connect to MySQL database",
	Run: func(cmd *cobra.Command, args []string) {
		runDatabaseCommand("mysql")
	},
}

var psqlCmd = &cobra.Command{
	Use:   "psql",
	Short: "Connect to PostgreSQL database",
	Run: func(cmd *cobra.Command, args []string) {
		runDatabaseCommand("psql")
	},
}

func runConsoleCommand(args []string) {
	if len(args) == 0 {
		fmt.Println("Usage: orodc-go console <command>")
		fmt.Println("Example: orodc-go console cache:clear")
		return
	}

	consoleArgs := append([]string{"php", "bin/console"}, args...)
	runCommandInContainer("", consoleArgs)
}

func runCLISession() {
	// Setup environment
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("🖥️  Opening interactive CLI session...")

	// Run interactive CLI container
	cliArgs := append(composeArgs, "run", "--rm", "-it", "cli")

	cliCmd := exec.Command("docker", cliArgs...)
	cliCmd.Stdout = os.Stdout
	cliCmd.Stderr = os.Stderr
	cliCmd.Stdin = os.Stdin

	if err := cliCmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ CLI session failed: %v\n", err)
		os.Exit(1)
	}
}

func runCommandInContainer(command string, args []string) {
	// Setup environment
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	var cmdArgs []string
	if command != "" {
		cmdArgs = append([]string{command}, args...)
	} else {
		cmdArgs = args
	}

	// Build docker compose run command
	dockerArgs := append(composeArgs, "run", "--rm", "cli")
	dockerArgs = append(dockerArgs, cmdArgs...)

	fmt.Printf("🐳 Running: %s %s\n", command, strings.Join(args, " "))

	cmd := exec.Command("docker", dockerArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Command failed: %v\n", err)
		os.Exit(1)
	}
}

func runDatabaseCommand(dbType string) {
	// Setup environment
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	var dbCmd string
	if dbType == "mysql" {
		dbCmd = "MYSQL_PWD=$DC_ORO_DATABASE_PASSWORD mysql -h$DC_ORO_DATABASE_HOST -P$DC_ORO_DATABASE_PORT -u$DC_ORO_DATABASE_USER $DC_ORO_DATABASE_DBNAME"
	} else if dbType == "psql" {
		dbCmd = "PGPASSWORD=$DC_ORO_DATABASE_PASSWORD psql -h $DC_ORO_DATABASE_HOST -p $DC_ORO_DATABASE_PORT -U $DC_ORO_DATABASE_USER -d $DC_ORO_DATABASE_DBNAME"
	}

	fmt.Printf("🗄️ Connecting to %s database...\n", dbType)

	// Run database command in database-cli container
	dockerArgs := append(composeArgs, "run", "--rm", "database-cli", "bash", "-c", dbCmd)

	dbCmdExec := exec.Command("docker", dockerArgs...)
	dbCmdExec.Stdout = os.Stdout
	dbCmdExec.Stderr = os.Stderr
	dbCmdExec.Stdin = os.Stdin

	if err := dbCmdExec.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Database connection failed: %v\n", err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(consoleCmd)
	rootCmd.AddCommand(cliCmd)
	rootCmd.AddCommand(composerCmd)
	rootCmd.AddCommand(phpCmd)
	rootCmd.AddCommand(npmCmd)
	rootCmd.AddCommand(nodeCmd)
	rootCmd.AddCommand(yarnCmd)
	rootCmd.AddCommand(bashCmd)
	rootCmd.AddCommand(mysqlCmd)
	rootCmd.AddCommand(psqlCmd)
}
