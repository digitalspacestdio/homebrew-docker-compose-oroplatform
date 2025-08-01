package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/tabwriter"

	"github.com/boykore/orodc-go/internal/config"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show status of all containers and services for current project",
	Long: `Display detailed status information for the current OroPlatform project including:
- Container status (running, stopped, etc.)
- Port mappings and URLs
- Health status
- Resource usage`,
	Run: runStatus,
}

type ContainerInfo struct {
	Names  string `json:"Names"`
	Status string `json:"Status"`
	State  string `json:"State"`
	Image  string `json:"Image"`
	Ports  string `json:"Ports"`
	Health string `json:"Health"`
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

func runStatus(cmd *cobra.Command, args []string) {
	// Show the OroDC header
	fmt.Print(GetOroDCHeader())
	fmt.Println("")
	fmt.Println("📊 Project Status Overview")
	fmt.Println("")

	// Get current directory as project directory
	appDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to get current directory: %v\n", err)
		os.Exit(1)
	}

	// Set project name based on directory
	projectName := filepath.Base(appDir)
	fmt.Printf("📁 Project: %s\n", projectName)
	fmt.Printf("📂 Directory: %s\n", appDir)
	fmt.Println("")

	// Setup environment to get port assignments
	composeArgs, err := config.SetupEnvironment()
	if err != nil {
		fmt.Printf("⚠️ Warning: Could not load environment: %v\n", err)
	}

	// Get all containers for this project
	containers := getProjectContainers(projectName)

	if len(containers) == 0 {
		fmt.Printf("❌ No containers found for project '%s'\n", projectName)
		fmt.Println("💡 Try running 'orodc-go up' to start the project")
		return
	}

	// Display container status
	displayContainerStatus(containers)
	fmt.Println("")

	// Display service URLs and ports
	displayServiceUrls(projectName)
	fmt.Println("")

	// Show compose command being used
	if len(composeArgs) > 0 {
		fmt.Printf("🐳 Docker Compose: docker %s\n", strings.Join(composeArgs, " "))
	}
}

func getProjectContainers(projectName string) []ContainerInfo {
	// Get all containers with JSON format
	cmd := exec.Command("docker", "ps", "-a", "--format", "json", "--filter", fmt.Sprintf("name=%s_", projectName))
	output, err := cmd.Output()
	if err != nil {
		return []ContainerInfo{}
	}

	var containers []ContainerInfo
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")

	for _, line := range lines {
		if line == "" {
			continue
		}

		var container ContainerInfo
		if err := json.Unmarshal([]byte(line), &container); err == nil {
			containers = append(containers, container)
		}
	}

	return containers
}

func displayContainerStatus(containers []ContainerInfo) {
	fmt.Println("🐳 Container Status:")

	// Create tabwriter for aligned output
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	// Headers
	fmt.Fprintln(w, "SERVICE\tSTATUS\tPORTS\tHEALTH\tIMAGE")
	fmt.Fprintln(w, "-------\t------\t-----\t------\t-----")

	for _, container := range containers {
		// Extract service name from container name (remove project prefix)
		serviceName := extractServiceName(container.Names)

		// Format status with emoji
		statusEmoji := getStatusEmoji(container.State, container.Status)
		status := fmt.Sprintf("%s %s", statusEmoji, container.State)

		// Format ports
		ports := formatPorts(container.Ports)

		// Format health
		health := formatHealth(container.Status)

		// Truncate image name
		image := truncateImage(container.Image)

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
			serviceName, status, ports, health, image)
	}

	w.Flush()
}

func extractServiceName(containerName string) string {
	// Remove leading slash and extract service name
	name := strings.TrimPrefix(containerName, "/")
	parts := strings.Split(name, "_")
	if len(parts) >= 2 {
		return parts[1] // Return service name (skip project prefix)
	}
	return name
}

func getStatusEmoji(state, status string) string {
	switch strings.ToLower(state) {
	case "running":
		if strings.Contains(strings.ToLower(status), "healthy") {
			return "✅"
		}
		return "🟢"
	case "exited":
		return "🔴"
	case "paused":
		return "⏸️"
	case "restarting":
		return "🔄"
	default:
		return "⚪"
	}
}

func formatPorts(portString string) string {
	if portString == "" {
		return "-"
	}

	// Parse port mappings and show only host ports
	ports := strings.Split(portString, ", ")
	var hostPorts []string

	for _, port := range ports {
		if strings.Contains(port, "->") {
			// Extract host port from "127.0.0.1:8080->80/tcp"
			parts := strings.Split(port, "->")
			if len(parts) > 0 {
				hostPart := parts[0]
				if strings.Contains(hostPart, ":") {
					portNum := strings.Split(hostPart, ":")[1]
					hostPorts = append(hostPorts, portNum)
				}
			}
		}
	}

	if len(hostPorts) > 0 {
		return strings.Join(hostPorts, ",")
	}
	return "-"
}

func formatHealth(status string) string {
	if strings.Contains(strings.ToLower(status), "healthy") {
		return "✅ Healthy"
	} else if strings.Contains(strings.ToLower(status), "unhealthy") {
		return "❌ Unhealthy"
	} else if strings.Contains(strings.ToLower(status), "starting") {
		return "🔄 Starting"
	}
	return "-"
}

func truncateImage(image string) string {
	// Remove registry and show only image:tag
	parts := strings.Split(image, "/")
	shortImage := parts[len(parts)-1]

	// Truncate if too long
	if len(shortImage) > 30 {
		return shortImage[:27] + "..."
	}
	return shortImage
}

func displayServiceUrls(projectName string) {
	fmt.Println("🌐 Service URLs:")

	// Get environment variables for ports
	nginxPort := os.Getenv("DC_ORO_PORT_NGINX")
	mailPort := os.Getenv("DC_ORO_PORT_MAIL_WEBGUI")
	xhguiPort := os.Getenv("DC_ORO_PORT_XHGUI")
	sshPort := os.Getenv("DC_ORO_PORT_SSH")
	dbPort := os.Getenv("DC_ORO_PORT_PGSQL")
	if dbPort == "" {
		dbPort = os.Getenv("DC_ORO_PORT_MYSQL")
	}
	searchPort := os.Getenv("DC_ORO_PORT_SEARCH")

	// Application URLs
	if nginxPort != "" {
		fmt.Printf("  🌍 Application:     https://%s.docker.local\n", projectName)
		fmt.Printf("      └─ Direct:      http://localhost:%s\n", nginxPort)
	}

	// Development tools
	if mailPort != "" {
		fmt.Printf("  📧 MailHog:         http://localhost:%s\n", mailPort)
	}
	if xhguiPort != "" {
		fmt.Printf("  🔍 XHProf:          http://localhost:%s\n", xhguiPort)
	}

	// Database & Infrastructure
	if dbPort != "" {
		fmt.Printf("  🗄️  Database:        localhost:%s\n", dbPort)
	}
	if searchPort != "" {
		fmt.Printf("  🔎 Elasticsearch:   http://localhost:%s\n", searchPort)
	}
	if sshPort != "" {
		fmt.Printf("  🔌 SSH:             ssh -p %s developer@localhost\n", sshPort)
	}
}
