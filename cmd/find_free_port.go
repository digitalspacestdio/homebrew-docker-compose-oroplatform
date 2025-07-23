package cmd

import (
	"bufio"
	"fmt"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

var findFreePortCmd = &cobra.Command{
	Use:   "find-free-port [projectName] [serviceName] [startPort] [composeConfigDir]",
	Short: "Find an available TCP port avoiding conflicts with local processes and Docker containers",
	Args:  cobra.ExactArgs(4),
	Run: func(cmd *cobra.Command, args []string) {
		projectName := args[0]
		serviceName := args[1]
		startPort, err := strconv.Atoi(args[2])
		if err != nil {
			fmt.Println("Invalid port number")
			os.Exit(1)
		}
		composeDir := args[3]
		composeFile := filepath.Join(composeDir, "compose.yml")

		usedPorts := make(map[int]struct{})
		foundPorts := make(map[int]struct{})

		// Get all published ports from compose.yml
		if _, err := os.Stat(composeFile); err == nil {
			data, _ := ioutil.ReadFile(composeFile)
			type PortDef struct {
				Published int `yaml:"published"`
			}
			type Service struct {
				Ports []PortDef `yaml:"ports"`
			}
			m := struct {
				Services map[string]Service `yaml:"services"`
			}{}
			yaml.Unmarshal(data, &m)
			for name, svc := range m.Services {
				for _, p := range svc.Ports {
					if name != serviceName {
						usedPorts[p.Published] = struct{}{}
					}
				}
			}
		}

		// Get ports used by local processes (lsof)
		for p := startPort; p <= 65535; p++ {
			addr := fmt.Sprintf(":%d", p)
			ln, err := net.Listen("tcp", addr)
			if err == nil {
				ln.Close()
			} else {
				usedPorts[p] = struct{}{}
			}
		}

		// Get ports used by other Docker containers (excluding current project/service)
		dockerCmd := exec.Command("docker", "ps", "-a", "--format", "{{.Names}} {{.Ports}}")
		output, err := dockerCmd.Output()
		if err == nil {
			scanner := bufio.NewScanner(strings.NewReader(string(output)))
			for scanner.Scan() {
				line := scanner.Text()
				parts := strings.SplitN(line, " ", 2)
				if len(parts) != 2 {
					continue
				}
				container := parts[0]
				ports := parts[1]

				projCmd := exec.Command("docker", "inspect", "--format", "{{ index .Config.Labels \"com.docker.compose.project\" }}", container)
				projOut, _ := projCmd.Output()
				contProject := strings.TrimSpace(string(projOut))

				svcCmd := exec.Command("docker", "inspect", "--format", "{{ index .Config.Labels \"com.docker.compose.service\" }}", container)
				svcOut, _ := svcCmd.Output()
				contService := strings.TrimSpace(string(svcOut))

				if contProject == projectName && contService == serviceName {
					continue
				}

				for _, portPart := range strings.Split(ports, ",") {
					portPart = strings.TrimSpace(portPart)
					if idx := strings.Index(portPart, "->"); idx != -1 {
						portRange := strings.TrimSuffix(portPart[:idx], "/tcp")
						if strings.Contains(portRange, ":") {
							portRange = portRange[strings.LastIndex(portRange, ":")+1:]
						}
						if p, err := strconv.Atoi(portRange); err == nil {
							usedPorts[p] = struct{}{}
						}
					}
				}
			}
		}

		// Find a free port
		for port := startPort; port <= 65535; port++ {
			if _, exists := foundPorts[port]; exists {
				continue
			}
			if _, inUse := usedPorts[port]; inUse {
				continue
			}
			ln, err := net.Listen("tcp", ":"+strconv.Itoa(port))
			if err == nil {
				ln.Close()
				fmt.Println(port)
				return
			}
		}
		fmt.Fprintln(os.Stderr, "Could not find a free port")
		os.Exit(1)
	},
}

func init() {
	rootCmd.AddCommand(findFreePortCmd)
}
