package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/boykore/orodc-go/internal/config"
	"github.com/spf13/cobra"
)

// ArgumentSet holds parsed command line arguments
type ArgumentSet struct {
	LeftFlags    []string
	LeftOptions  []string
	Args         []string
	RightFlags   []string
	RightOptions []string
}

var upCmd = &cobra.Command{
	Use:   "up [flags] [services...]",
	Short: "Start the Oro environment (docker-compose up)",
	Long: `Start the OroPlatform development environment using docker-compose.

Examples:
  orodc-go up                     # Start all services in foreground
  orodc-go up -d                  # Start all services in background (detached)
  orodc-go --file custom.yml up -d --build   # Custom compose file with build
  orodc-go up database redis      # Start only specific services
  orodc-go up -d --remove-orphans # Start in background and remove orphans`,
	DisableFlagParsing: true, // We'll parse flags manually like bash script
	Run: func(cmd *cobra.Command, args []string) {
		runUp(args)
	},
}

// parseArguments replicates the bash script's argument parsing logic
func parseArguments(input []string) ArgumentSet {
	result := ArgumentSet{}
	i := 0
	sawFirstArg := false

	for i < len(input) {
		arg := input[i]
		var next string
		if i+1 < len(input) {
			next = input[i+1]
		}

		// Handle --option=value format
		if strings.HasPrefix(arg, "--") && strings.Contains(arg, "=") {
			if !sawFirstArg {
				result.LeftOptions = append(result.LeftOptions, arg)
			} else {
				result.RightOptions = append(result.RightOptions, arg)
			}
			i++

			// Handle --option value format
		} else if strings.HasPrefix(arg, "--") && !strings.HasPrefix(next, "-") && next != "" {
			if !sawFirstArg {
				result.LeftOptions = append(result.LeftOptions, arg, next)
			} else {
				result.RightOptions = append(result.RightOptions, arg, next)
			}
			i += 2

			// Handle flags like -d, -f, etc.
		} else if strings.HasPrefix(arg, "-") {
			if !sawFirstArg {
				result.LeftFlags = append(result.LeftFlags, arg)
			} else {
				result.RightFlags = append(result.RightFlags, arg)
			}
			i++

			// Handle command arguments
		} else {
			result.Args = append(result.Args, arg)
			sawFirstArg = true
			i++
		}
	}

	return result
}

func runUp(args []string) {
	// Show the OroDC header for important commands
	fmt.Print(GetOroDCHeader())
	fmt.Println("")
	fmt.Println("🚀 Starting OroPlatform development environment...")
	fmt.Println("")

	// Setup environment and get compose file paths
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Environment setup failed: %v\n", err)
		os.Exit(1)
	}

	// Parse arguments like bash script does
	parsed := parseArguments(args)

	// Special handling for up command: ensure "up" is always the first argument
	// and any additional args are services
	if len(parsed.Args) == 0 {
		// No explicit args provided (only flags), treat all flags as "right flags" for "up"
		parsed.RightFlags = append(parsed.LeftFlags, parsed.RightFlags...)
		parsed.RightOptions = append(parsed.LeftOptions, parsed.RightOptions...)
		parsed.LeftFlags = []string{}
		parsed.LeftOptions = []string{}
		parsed.Args = []string{"up"}
	} else {
		// Args provided, prepend "up" to make them services for the up command
		parsed.Args = append([]string{"up"}, parsed.Args...)
	}

	// Debug output (like bash script)
	if os.Getenv("DEBUG") != "" {
		fmt.Printf("Left Flags: %v\n", parsed.LeftFlags)
		fmt.Printf("Left Options: %v\n", parsed.LeftOptions)
		fmt.Printf("Args: %v\n", parsed.Args)
		fmt.Printf("Right Flags: %v\n", parsed.RightFlags)
		fmt.Printf("Right Options: %v\n", parsed.RightOptions)
	}

	// Build docker command: docker compose [left_flags] [left_options] [args] [right_flags] [right_options]
	dockerArgs := composeArgs
	dockerArgs = append(dockerArgs, parsed.LeftFlags...)
	dockerArgs = append(dockerArgs, parsed.LeftOptions...)
	dockerArgs = append(dockerArgs, parsed.Args...)
	dockerArgs = append(dockerArgs, parsed.RightFlags...)
	dockerArgs = append(dockerArgs, parsed.RightOptions...)

	fmt.Printf("🐳 Running: docker %s\n", strings.Join(dockerArgs, " "))

	// Execute docker compose command
	composeCmd := exec.Command("docker", dockerArgs...)
	composeCmd.Stdout = os.Stdout
	composeCmd.Stderr = os.Stderr
	composeCmd.Stdin = os.Stdin

	if err := composeCmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to run docker-compose: %v\n", err)
		os.Exit(1)
	}

	// Only show success message if running in detached mode
	if contains(parsed.RightFlags, "-d") || contains(parsed.RightFlags, "--detach") {
		fmt.Println("✅ Oro environment is up and running in background!")
	}
}

// Helper function to check if slice contains a value
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func init() {
	rootCmd.AddCommand(upCmd)
}
