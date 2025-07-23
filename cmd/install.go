package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var withoutDemo bool

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run OroPlatform installation (with or without demo data)",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔧 Starting Oro installation...")
		runInstall()
	},
}

func init() {
	installCmd.Flags().BoolVar(&withoutDemo, "without-demo", false, "Install without demo data")
	rootCmd.AddCommand(installCmd)
}

func runInstall() {
	appDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to detect working directory: %v\n", err)
		os.Exit(1)
	}

	// Set env
	os.Setenv("XDEBUG_MODE", "off")

	// Clear cache
	fmt.Println("🧹 Clearing var/cache...")
	_ = exec.Command("rm", "-rf", appDir+"/var/cache").Run()

	// Run composer install
	fmt.Println("📦 Running composer install...")
	runCommand("docker", "compose", "run", "--rm", "cli", "composer", "install")

	// Run oro:install
	fmt.Println("⚙️  Running oro:install...")
	sampleData := "y"
	if withoutDemo {
		sampleData = "n"
	}
	installArgs := []string{
		"compose", "run", "--rm", "cli", "php", "bin/console",
		"--env=prod", "--timeout=1800", "oro:install",
		"--language=en",
		"--formatting-code=en_US",
		"--organization-name=Acme Inc.",
		"--user-name=admin",
		"--user-email=admin@example.com",
		"--user-firstname=John",
		"--user-lastname=Doe",
		"--user-password=$ecretPassw0rd",
		fmt.Sprintf("--application-url=https://%s.docker.local/", os.Getenv("DC_ORO_NAME")),
		"--sample-data=" + sampleData,
	}
	runCommand("docker", installArgs...)
	fmt.Println("✅ Installation finished!")
}

func runCommand(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Command failed: %v\n", err)
		os.Exit(1)
	}
}
