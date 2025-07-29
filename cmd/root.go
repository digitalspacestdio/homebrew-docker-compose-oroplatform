package cmd

import (
	"fmt"
	"os"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

// GetOroDCLogo returns the ASCII art logo for OroDC
func GetOroDCLogo() string {
	return `
 ██████╗ ██████╗  ██████╗ ██████╗  ██████╗
██╔═══██╗██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║   ██║██████╔╝██║   ██║██║  ██║██║     
██║   ██║██╔══██╗██║   ██║██║  ██║██║     
╚██████╔╝██║  ██║╚██████╔╝██████╔╝╚██████╗
 ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝
                                          
🐳 Docker-based OroPlatform Development Environment
⚡ Powered by Docker Compose & PHP 8.x`
}

// GetOroDCHeader returns a compact header for commands
func GetOroDCHeader() string {
	return `
╔═══════════════════════════════════════════════════════════╗
║  ██████╗ ██████╗  ██████╗ ██████╗  ██████╗               ║
║ ██╔═══██╗██╔══██╗██╔═══██╗██╔══██╗██╔════╝               ║
║ ██║   ██║██████╔╝██║   ██║██║  ██║██║                    ║
║ ██║   ██║██╔══██╗██║   ██║██║  ██║██║                    ║
║ ╚██████╔╝██║  ██║╚██████╔╝██████╔╝╚██████╗               ║
║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝               ║
║                                                           ║
║  🐳 OroPlatform Development Environment Manager           ║
╚═══════════════════════════════════════════════════════════╝`
}

var rootCmd = &cobra.Command{
	Use:   "orodc-go",
	Short: "OroDC CLI utility for Oro developer environments",
	Long: GetOroDCLogo() + `

OroDC (Oro Docker Compose) helps manage docker-based OroPlatform development environments.

Features:
• 🚀 Quick OroPlatform setup and installation
• 🐳 Docker Compose orchestration
• 🔧 Database management (MySQL/PostgreSQL)
• 🌐 Service networking and port management
• 📦 Volume and data persistence
• 🔑 SSH access and key management
• ⚡ PHP/Node.js version detection
• 🧹 Environment cleanup and purging

Perfect for OroPlatform developers who want a streamlined Docker-based workflow!`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print(GetOroDCLogo())
		fmt.Println("\n")
		fmt.Println("🚀 Welcome to OroDC - OroPlatform Development Environment Manager!")
		fmt.Println("")
		fmt.Println("📚 Use `orodc-go --help` to see all available commands.")
		fmt.Println("🎯 Use `orodc-go install` to setup a new OroPlatform environment.")
		fmt.Println("🐳 Use `orodc-go up -d` to start your development environment.")
		fmt.Println("")
		fmt.Println("💡 Pro tip: Run commands from your OroPlatform project directory!")
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show OroDC version information",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print(GetOroDCLogo())
		fmt.Println("\n")

		// Get version info from centralized system
		versionInfo := config.GetVersionInfo()

		fmt.Println("📦 OroDC (Oro Docker Compose) - Golang Edition")
		fmt.Printf("🏷️  Version: %s\n", versionInfo["version"])
		fmt.Printf("🔧 Git Commit: %s\n", versionInfo["gitCommit"])
		fmt.Printf("📅 Build Date: %s\n", versionInfo["buildDate"])
		fmt.Println("🐳 Docker Compose support: ✅")
		fmt.Println("🔧 OroPlatform support: ✅")
		fmt.Println("⚡ PHP 8.x support: ✅")
		fmt.Println("")
		fmt.Println("💻 Built with Go and Cobra CLI framework")
		fmt.Println("🚀 Equivalent functionality to bash version")
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
