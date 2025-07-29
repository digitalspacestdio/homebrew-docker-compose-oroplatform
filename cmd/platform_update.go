package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var platformUpdateCmd = &cobra.Command{
	Use:   "platform-update [url]",
	Short: "Run oro:platform:update inside the container",
	Long: `Run OroPlatform database schema and data updates inside the CLI container.

This command will:
- Run oro:platform:update --force to update database schema
- Update application URLs in the configuration
- Handle the update process safely with error handling

Optional URL parameter can be provided to set custom application URL.
If not provided, defaults to https://PROJECT_NAME.docker.local/`,
	Args: cobra.MaximumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		runPlatformUpdate(args)
	},
}

func runPlatformUpdate(args []string) {
	fmt.Println("⚙️ Running oro:platform:update...")

	// Setup environment and get compose file paths (same as bash version)
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	// Get URL from args or default (same as bash script logic)
	projectName := os.Getenv("DC_ORO_NAME")
	url := fmt.Sprintf("https://%s.docker.local", projectName)
	if len(args) > 0 {
		url = args[0]
	}

	fmt.Printf("🌐 Using application URL: %s\n", url)

	// Run oro:platform:update --force (same as bash script)
	fmt.Println("🔄 Running oro:platform:update --force...")

	// Build docker compose run command (like bash DOCKER_COMPOSE_RUN_CMD)
	updateArgs := append(composeArgs, "run", "-q", "--rm", "cli", "bash", "-c",
		"php bin/console oro:platform:update --force")

	// Show debug output like bash script does (set -x)
	if os.Getenv("DEBUG") != "" {
		fmt.Printf("🐳 Running: docker %v\n", updateArgs)
	}

	updateCmd := exec.Command("docker", updateArgs...)
	updateCmd.Stdout = os.Stdout
	updateCmd.Stderr = os.Stderr
	updateCmd.Stdin = os.Stdin

	// Run with error handling like bash script (|| true)
	if err := updateCmd.Run(); err != nil {
		fmt.Printf("⚠️ Warning: oro:platform:update command failed: %v\n", err)
		fmt.Printf("💡 This might be normal if no updates are needed\n")
	} else {
		fmt.Printf("✅ oro:platform:update completed successfully\n")
	}

	// Update application URLs like bash script does (lines 506-508)
	fmt.Println("🔧 Updating application URLs...")

	updateConfigs := []string{
		"oro_website.secure_url",
		"oro_ui.application_url",
		"oro_website.url",
	}

	for _, configKey := range updateConfigs {
		configArgs := append(composeArgs, "run", "-q", "--rm", "cli", "bash", "-c",
			fmt.Sprintf("php bin/console oro:config:update %s %s", configKey, url))

		if os.Getenv("DEBUG") != "" {
			fmt.Printf("🐳 Running: docker %v\n", configArgs)
		}

		configCmd := exec.Command("docker", configArgs...)
		configCmd.Stdout = os.Stdout
		configCmd.Stderr = os.Stderr

		// Run with error handling like bash script (|| true)
		if err := configCmd.Run(); err != nil {
			fmt.Printf("⚠️ Warning: Failed to update %s: %v\n", configKey, err)
		} else {
			fmt.Printf("✅ Updated %s to: %s\n", configKey, url)
		}
	}

	fmt.Println("✅ Platform update process completed!")
}

func init() {
	rootCmd.AddCommand(platformUpdateCmd)
}
