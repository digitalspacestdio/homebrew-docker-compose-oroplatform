package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var sshCmd = &cobra.Command{
	Use:   "ssh [command...]",
	Short: "Connect to the development environment via SSH",
	Long: `Connect to the OroPlatform development environment via SSH.
	
Examples:
  orodc-go ssh                    # Interactive SSH session
  orodc-go ssh php bin/console    # Run console command
  orodc-go ssh composer install   # Run composer
  orodc-go ssh bash               # Interactive bash shell`,
	Run: func(cmd *cobra.Command, args []string) {
		connectSSH(args)
	},
}

func connectSSH(args []string) {
	// Setup environment to get proper variables
	_, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	// Get project name and paths
	projectDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to get current directory: %v\n", err)
		os.Exit(1)
	}

	projectName := filepath.Base(projectDir)
	configDir := fmt.Sprintf("%s/.orodc/%s", os.Getenv("HOME"), projectName)
	sshKeyPath := fmt.Sprintf("%s/ssh_id_ed25519", configDir)

	// Get SSH port from running container (use actual environment values)
	phpVersion := os.Getenv("DC_ORO_PHP_VERSION")
	nodeVersion := os.Getenv("DC_ORO_NODE_VERSION")
	if phpVersion == "" {
		phpVersion = "8.3" // fallback
	}
	if nodeVersion == "" {
		nodeVersion = "20" // fallback
	}

	inspectCmd := exec.Command("docker", "inspect", fmt.Sprintf("%s_ssh_%s-%s-2",
		projectName, phpVersion, nodeVersion),
		"--format", `{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}`)

	output, err := inspectCmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to get SSH port. Is the environment running? Try: orodc-go up -d\n")
		os.Exit(1)
	}

	sshPort := strings.TrimSpace(string(output))
	if sshPort == "" {
		fmt.Fprintf(os.Stderr, "❌ SSH container not running. Try: orodc-go up -d\n")
		os.Exit(1)
	}

	fmt.Printf("🔗 Connecting to SSH on port %s\n", sshPort)

	// Get user name
	userName := os.Getenv("DC_ORO_USER_NAME")
	if userName == "" {
		userName = "developer" // fallback
	}

	// Build SSH command
	sshArgs := []string{
		"ssh",
		"-o", "SendEnv=COMPOSER_AUTH",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "StrictHostKeyChecking=no",
		"-i", sshKeyPath,
		"-p", sshPort,
		fmt.Sprintf("%s@127.0.0.1", userName),
	}

	// Add any additional arguments
	sshArgs = append(sshArgs, args...)

	// Execute SSH connection
	sshCmd := exec.Command("ssh", sshArgs[1:]...)
	sshCmd.Stdout = os.Stdout
	sshCmd.Stderr = os.Stderr
	sshCmd.Stdin = os.Stdin

	if err := sshCmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ SSH connection failed: %v\n", err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(sshCmd)
}
