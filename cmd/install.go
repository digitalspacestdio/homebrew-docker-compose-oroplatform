package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

var withoutDemo bool

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run OroPlatform installation (with or without demo data)",
	Long: `Install OroPlatform with all required dependencies and configuration.

This command will:
• Set up Docker containers (PHP, database, search, etc.)
• Install Composer dependencies  
• Run oro:install with sample data
• Configure database and application settings
• Generate OAuth 2.0 keys for API access

Use --without-demo flag to install without sample data.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Show the OroDC header
		fmt.Print(GetOroDCHeader())
		fmt.Println("")
		fmt.Println("🔧 Starting OroPlatform installation...")
		fmt.Println("")
		runInstall()
	},
}

func init() {
	installCmd.Flags().BoolVar(&withoutDemo, "without-demo", false, "Install without demo data")
	rootCmd.AddCommand(installCmd)
}

func runInstall() {
	// Setup environment and get compose file paths (this parses DSN and sets all env vars)
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	// Show what credentials we'll use
	fmt.Printf("🔧 Will use database credentials:\n")
	fmt.Printf("   User: %s\n", os.Getenv("DC_ORO_DATABASE_USER"))
	fmt.Printf("   Database: %s\n", os.Getenv("DC_ORO_DATABASE_DBNAME"))
	fmt.Printf("   Host: %s\n", os.Getenv("DC_ORO_DATABASE_HOST"))
	fmt.Printf("   Port: %s\n", os.Getenv("DC_ORO_DATABASE_PORT"))

	// Clean up any orphan containers (this removes containers with old credentials)
	if err := config.CleanupOrphans(composeArgs); err != nil {
		fmt.Fprintf(os.Stderr, "⚠️ Warning: Failed to cleanup orphans: %v\n", err)
	}

	// Set env
	os.Setenv("XDEBUG_MODE", "off")

	// Start database container with correct credentials parsed from DSN
	fmt.Println("🗄️ Starting database container with parsed credentials...")
	startDbArgs := append(composeArgs, "up", "-d", "database")
	runCommand("docker", startDbArgs...)

	// Wait a moment for database to initialize
	fmt.Println("⏳ Waiting for database to initialize...")
	waitCmd := exec.Command("sleep", "3")
	waitCmd.Run()

	// Now ensure database is ready (create if doesn't exist)
	fmt.Println("🗄️ Ensuring database is ready...")
	if err := config.EnsureDatabaseReady(composeArgs); err != nil {
		fmt.Fprintf(os.Stderr, "⚠️ Warning: Database setup check failed: %v\n", err)
	}

	// Clear cache inside container (like bash version)
	fmt.Println("🧹 Clearing var/cache...")
	cacheArgs := append(composeArgs, "run", "--rm", "cli", "bash", "-c",
		"[[ -d ${DC_ORO_APPDIR}/var/cache ]] && rm -rf ${DC_ORO_APPDIR}/var/cache/* || true")
	runCommand("docker", cacheArgs...)

	// Run composer install
	fmt.Println("📦 Running composer install...")
	composerArgs := append(composeArgs, "run", "--rm", "cli", "composer", "install")
	runCommand("docker", composerArgs...)

	// Run oro:install
	fmt.Println("⚙️  Running oro:install...")
	sampleData := "y"
	if withoutDemo {
		sampleData = "n"
	}

	installArgs := append(composeArgs, "run", "--rm", "cli", "php", "bin/console",
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
		"--sample-data="+sampleData,
	)
	runCommand("docker", installArgs...)

	// Generate OAuth 2.0 private/public keys (required for OroPlatform API)
	fmt.Println("🔐 Generating OAuth 2.0 keys...")
	oauthArgs := append(composeArgs, "run", "--rm", "cli", "php", "bin/console",
		"oro:oauth-server:generate-keys", "--env=prod")

	// Try to run OAuth key generation, but don't fail if command doesn't exist
	oauthCmd := exec.Command("docker", oauthArgs...)
	oauthCmd.Stdout = os.Stdout
	oauthCmd.Stderr = os.Stderr
	oauthCmd.Stdin = os.Stdin

	if err := oauthCmd.Run(); err != nil {
		fmt.Printf("⚠️ OAuth key generation failed, trying alternative method...\n")

		// Try alternative approach - create keys directory and generate manually
		keyGenArgs := append(composeArgs, "run", "--rm", "cli", "bash", "-c", `
			mkdir -p var/oauth &&
			cd var/oauth &&
			if [ ! -f private.key ]; then
				openssl genpkey -algorithm RSA -out private.key -pkcs8 -pass pass:
				openssl rsa -in private.key -pubout -out public.key
				chmod 600 private.key
				chmod 644 public.key
				echo "OAuth keys generated successfully"
			else
				echo "OAuth keys already exist"
			fi
		`)

		keyGenCmd := exec.Command("docker", keyGenArgs...)
		keyGenCmd.Stdout = os.Stdout
		keyGenCmd.Stderr = os.Stderr

		if err := keyGenCmd.Run(); err != nil {
			fmt.Printf("⚠️ Warning: Failed to generate OAuth keys manually: %v\n", err)
			fmt.Printf("💡 You may need to generate OAuth keys manually after installation\n")
		} else {
			fmt.Printf("✅ OAuth keys generated successfully\n")
		}
	} else {
		fmt.Printf("✅ OAuth keys generated successfully\n")
	}

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
