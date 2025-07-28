package config

import (
	"bufio"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
)

func LoadEnvSafe(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "#") || len(line) == 0 {
			continue
		}
		if !strings.Contains(line, "=") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		key := strings.TrimSpace(parts[0])
		value := strings.Trim(strings.TrimSpace(parts[1]), `"'`)
		os.Setenv(key, value)
	}
	return nil
}

func loadProjectEnvFiles(appDir string) error {
	// Load environment files in the same order as bash version
	envFiles := []string{
		filepath.Join(appDir, ".env"),
		filepath.Join(appDir, ".env-app"),
		filepath.Join(appDir, ".env-app.local"),
		filepath.Join(appDir, ".env.orodc"),
	}

	for _, envFile := range envFiles {
		if _, err := os.Stat(envFile); err == nil {
			fmt.Printf("📄 Loading environment file: %s\n", filepath.Base(envFile))
			LoadEnvSafe(envFile)
		}
	}
	return nil
}

// parseDsnUri parses a database DSN URI and sets environment variables
// This replicates the bash version's parse_dsn_uri function
func parseDsnUri(uri, name, prefix string) {
	if uri == "" || name == "" {
		return
	}

	// Build variable prefix (same as bash version)
	var varPrefix string
	if prefix != "" {
		varPrefix = strings.ToUpper(prefix) + "_"
	}
	varPrefix += strings.ToUpper(name) + "_"

	fmt.Printf("🔍 Parsing DSN: %s\n", uri)

	// Parse URI components
	var schema, user, password, host, port, dbname, query string

	// Extract schema
	if strings.Contains(uri, "://") {
		parts := strings.SplitN(uri, "://", 2)
		schema = parts[0]
		rest := parts[1]

		// Extract query parameters
		if strings.Contains(rest, "?") {
			queryParts := strings.SplitN(rest, "?", 2)
			rest = queryParts[0]
			query = queryParts[1]
		}

		// Extract user:password@host:port/database
		if strings.Contains(rest, "@") {
			// Has user info
			authParts := strings.SplitN(rest, "@", 2)
			userInfo := authParts[0]
			hostInfo := authParts[1]

			// Parse user:password
			if strings.Contains(userInfo, ":") {
				userParts := strings.SplitN(userInfo, ":", 2)
				user = userParts[0]
				password = userParts[1]
			} else {
				user = userInfo
				password = "app" // default from bash version
			}

			// Parse host:port/database
			rest = hostInfo
		}

		// Parse host:port/database
		if strings.Contains(rest, "/") {
			hostParts := strings.SplitN(rest, "/", 2)
			hostPort := hostParts[0]
			dbname = hostParts[1]

			// Parse host:port
			if strings.Contains(hostPort, ":") {
				hostPortParts := strings.SplitN(hostPort, ":", 2)
				host = hostPortParts[0]
				port = hostPortParts[1]
			} else {
				host = hostPort
			}
		} else if strings.Contains(rest, ":") {
			// Just host:port, no database
			hostPortParts := strings.SplitN(rest, ":", 2)
			host = hostPortParts[0]
			port = hostPortParts[1]
		} else {
			// Just host
			host = rest
		}
	} else {
		// Simple schema without ://
		schema = uri
	}

	// Convert localhost to container name (same as bash version)
	if host == "localhost" || host == "127.0.0.1" {
		host = strings.ToLower(name) // "database" for database service
	}

	// Set environment variables (same as bash version)
	if schema != "" {
		os.Setenv(varPrefix+"SCHEMA", schema)
		fmt.Printf("🗄️ Set %sSCHEMA=%s\n", varPrefix, schema)
	}
	if user != "" {
		os.Setenv(varPrefix+"USER", user)
		fmt.Printf("👤 Set %sUSER=%s\n", varPrefix, user)
	}
	if password != "" {
		os.Setenv(varPrefix+"PASSWORD", password)
		fmt.Printf("🔑 Set %sPASSWORD=%s\n", varPrefix, "***")
	}
	if host != "" {
		os.Setenv(varPrefix+"HOST", host)
		fmt.Printf("🏠 Set %sHOST=%s\n", varPrefix, host)
	}
	if port != "" {
		os.Setenv(varPrefix+"PORT", port)
		fmt.Printf("🔌 Set %sPORT=%s\n", varPrefix, port)
	}
	if dbname != "" {
		os.Setenv(varPrefix+"DBNAME", dbname)
		fmt.Printf("🗃️ Set %sDBNAME=%s\n", varPrefix, dbname)
	}
	if query != "" {
		os.Setenv(varPrefix+"QUERY", query)
	}

	// Reconstruct clean URI
	var cleanUri string
	if schema != "" {
		cleanUri = schema + "://"
		if user != "" {
			cleanUri += user
			if password != "" {
				cleanUri += ":" + password
			}
			cleanUri += "@"
		}
		if host != "" {
			cleanUri += host
			if port != "" {
				cleanUri += ":" + port
			}
		}
		if dbname != "" {
			cleanUri += "/" + dbname
		}
		if query != "" {
			cleanUri += "?" + query
		}
		os.Setenv(varPrefix+"URI", cleanUri)
	}
}

func detectDatabaseSchemaFromDSN(dsn string) string {
	if dsn == "" {
		return ""
	}

	// Parse the DSN to get the schema
	if u, err := url.Parse(dsn); err == nil {
		schema := u.Scheme

		// Map common database schemes
		switch schema {
		case "mysql", "mariadb":
			return "mysql"
		case "postgres", "postgresql", "pgsql":
			return "pgsql"
		case "pdo_mysql":
			return "mysql"
		case "pdo_pgsql":
			return "pgsql"
		}

		return schema
	}

	// Fallback: try to detect from string prefix
	dsn = strings.ToLower(dsn)
	if strings.HasPrefix(dsn, "mysql") || strings.HasPrefix(dsn, "mariadb") {
		return "mysql"
	}
	if strings.HasPrefix(dsn, "postgres") || strings.HasPrefix(dsn, "pgsql") {
		return "pgsql"
	}

	return ""
}

func ensureDatabaseExists(composeArgs []string, databaseSchema string) {
	dbName := os.Getenv("DC_ORO_DATABASE_DBNAME")
	if dbName == "" {
		return
	}

	fmt.Printf("🔍 Checking if database '%s' exists...\n", dbName)

	var checkCmd *exec.Cmd
	var databaseExists bool

	if databaseSchema == "mysql" || databaseSchema == "mariadb" {
		// MySQL check - use SHOW DATABASES
		checkArgs := append(composeArgs, "exec", "-T", "database", "mysql",
			"-u"+os.Getenv("DC_ORO_DATABASE_USER"),
			"-p"+os.Getenv("DC_ORO_DATABASE_PASSWORD"),
			"-e", fmt.Sprintf("SHOW DATABASES LIKE '%s'", dbName))
		checkCmd = exec.Command("docker", checkArgs...)

		if output, err := checkCmd.Output(); err == nil {
			outputStr := strings.TrimSpace(string(output))
			// If output contains the database name, it exists
			databaseExists = strings.Contains(outputStr, dbName)
		} else {
			fmt.Printf("⚠️ Failed to check MySQL database existence: %v\n", err)
			databaseExists = false
		}
	} else {
		// PostgreSQL check - use a more reliable approach
		checkArgs := append(composeArgs, "exec", "-T", "database", "psql",
			"-U", os.Getenv("DC_ORO_DATABASE_USER"),
			"-d", "postgres",
			"-tc", fmt.Sprintf("SELECT 1 FROM pg_database WHERE datname='%s'", dbName))
		checkCmd = exec.Command("docker", checkArgs...)

		if output, err := checkCmd.Output(); err == nil {
			outputStr := strings.TrimSpace(string(output))
			// If output contains "1", the database exists
			databaseExists = outputStr == "1"
			fmt.Printf("🔍 PostgreSQL check output: '%s'\n", outputStr)
		} else {
			fmt.Printf("⚠️ Failed to check PostgreSQL database existence: %v\n", err)
			databaseExists = false
		}
	}

	if databaseExists {
		fmt.Printf("✅ Database '%s' already exists\n", dbName)
		return
	}

	// Database doesn't exist, create it
	fmt.Printf("📊 Database '%s' does not exist, creating...\n", dbName)

	var createCmd *exec.Cmd
	if databaseSchema == "mysql" || databaseSchema == "mariadb" {
		// MySQL create
		createArgs := append(composeArgs, "exec", "-T", "database", "mysql",
			"-u"+os.Getenv("DC_ORO_DATABASE_USER"),
			"-p"+os.Getenv("DC_ORO_DATABASE_PASSWORD"),
			"-e", fmt.Sprintf("CREATE DATABASE IF NOT EXISTS %s", dbName))
		createCmd = exec.Command("docker", createArgs...)
	} else {
		// PostgreSQL create with error handling
		createArgs := append(composeArgs, "exec", "-T", "database", "psql",
			"-U", os.Getenv("DC_ORO_DATABASE_USER"),
			"-d", "postgres",
			"-c", fmt.Sprintf("SELECT 'CREATE DATABASE %s' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '%s')\\gexec", dbName, dbName))
		createCmd = exec.Command("docker", createArgs...)
	}

	createCmd.Stdout = os.Stdout
	createCmd.Stderr = os.Stderr
	if err := createCmd.Run(); err != nil {
		// Try alternative approach for PostgreSQL if the smart create failed
		if databaseSchema != "mysql" && databaseSchema != "mariadb" {
			fmt.Printf("⚠️ Smart create failed, trying direct CREATE DATABASE...\n")
			directCreateArgs := append(composeArgs, "exec", "-T", "database", "psql",
				"-U", os.Getenv("DC_ORO_DATABASE_USER"),
				"-d", "postgres",
				"-c", fmt.Sprintf("CREATE DATABASE %s;", dbName))
			directCreateCmd := exec.Command("docker", directCreateArgs...)
			directCreateCmd.Stdout = os.Stdout
			directCreateCmd.Stderr = os.Stderr
			if err2 := directCreateCmd.Run(); err2 != nil {
				if strings.Contains(err2.Error(), "already exists") {
					fmt.Printf("✅ Database '%s' already exists (from creation attempt)\n", dbName)
				} else {
					fmt.Printf("⚠️ Warning: Failed to create database '%s': %v\n", dbName, err2)
				}
			} else {
				fmt.Printf("✅ Database '%s' created successfully\n", dbName)
			}
		} else {
			fmt.Printf("⚠️ Warning: Failed to create database '%s': %v\n", dbName, err)
		}
	} else {
		fmt.Printf("✅ Database '%s' created successfully\n", dbName)
	}
}

func setupDatabaseDefaults() string {
	// First check if we have ORO_DB_URL from .env files (same as bash version)
	oroDbUrl := os.Getenv("ORO_DB_URL")

	if oroDbUrl != "" {
		fmt.Printf("📋 Found ORO_DB_URL in project: %s\n", oroDbUrl)
		// Parse DSN to extract actual credentials (same as bash version)
		parseDsnUri(oroDbUrl, "database", "DC_ORO")
	} else {
		fmt.Printf("📋 No ORO_DB_URL found, using defaults\n")
	}

	// Parse other DSNs just like bash script does
	if oroSearchUrl := os.Getenv("ORO_SEARCH_URL"); oroSearchUrl != "" {
		fmt.Printf("🔍 Found ORO_SEARCH_URL: %s\n", oroSearchUrl)
		parseDsnUri(oroSearchUrl, "search", "DC_ORO")
	}

	if oroMqDsn := os.Getenv("ORO_MQ_DSN"); oroMqDsn != "" {
		fmt.Printf("📨 Found ORO_MQ_DSN: %s\n", oroMqDsn)
		parseDsnUri(oroMqDsn, "mq", "DC_ORO")
	}

	if oroRedisUrl := os.Getenv("ORO_REDIS_URL"); oroRedisUrl != "" {
		fmt.Printf("🔴 Found ORO_REDIS_URL: %s\n", oroRedisUrl)
		parseDsnUri(oroRedisUrl, "redis", "DC_ORO")
	}

	// Get detected schema or detect from parsed DSN
	databaseSchema := os.Getenv("DC_ORO_DATABASE_SCHEMA")
	if databaseSchema == "" {
		databaseSchema = detectDatabaseSchemaFromDSN(oroDbUrl)
	}

	// Set DC_ORO_DATABASE_SCHEMA for compose file selection
	if databaseSchema != "" {
		os.Setenv("DC_ORO_DATABASE_SCHEMA", databaseSchema)
		fmt.Printf("🗄️ Detected database schema: %s\n", databaseSchema)
	} else {
		// Default to PostgreSQL if no schema detected
		databaseSchema = "pgsql"
		os.Setenv("DC_ORO_DATABASE_SCHEMA", databaseSchema)
		fmt.Printf("🗄️ Using default database schema: %s\n", databaseSchema)
	}

	// Set default database credentials ONLY if not already set (same as bash version)
	if os.Getenv("DC_ORO_DATABASE_USER") == "" {
		os.Setenv("DC_ORO_DATABASE_USER", "app")
		fmt.Printf("👤 Using default database user: app\n")
	}
	if os.Getenv("DC_ORO_DATABASE_PASSWORD") == "" {
		os.Setenv("DC_ORO_DATABASE_PASSWORD", "app")
		fmt.Printf("🔑 Using default database password: app\n")
	}
	if os.Getenv("DC_ORO_DATABASE_HOST") == "" {
		os.Setenv("DC_ORO_DATABASE_HOST", "database")
		fmt.Printf("🏠 Using default database host: database\n")
	}
	if os.Getenv("DC_ORO_DATABASE_DBNAME") == "" {
		os.Setenv("DC_ORO_DATABASE_DBNAME", "app")
		fmt.Printf("🗃️ Using default database name: app\n")
	}

	// Set port based on database type
	if os.Getenv("DC_ORO_DATABASE_PORT") == "" {
		if databaseSchema == "mysql" || databaseSchema == "mariadb" {
			os.Setenv("DC_ORO_DATABASE_PORT", "3306")
			fmt.Printf("🔌 Using default MySQL port: 3306\n")
		} else {
			os.Setenv("DC_ORO_DATABASE_PORT", "5432")
			fmt.Printf("🔌 Using default PostgreSQL port: 5432\n")
		}
	}

	// Set up Message Queue defaults if not already configured
	if os.Getenv("DC_ORO_MQ_USER") == "" {
		os.Setenv("DC_ORO_MQ_USER", "app")
	}
	if os.Getenv("DC_ORO_MQ_PASSWORD") == "" {
		os.Setenv("DC_ORO_MQ_PASSWORD", "app")
	}
	if os.Getenv("DC_ORO_MQ_HOST") == "" {
		os.Setenv("DC_ORO_MQ_HOST", "mq")
	}
	if os.Getenv("DC_ORO_MQ_PORT") == "" {
		os.Setenv("DC_ORO_MQ_PORT", "5672")
	}

	// Generate MQ DSN if not already set (critical for OroPlatform)
	if os.Getenv("ORO_MQ_DSN") == "" && os.Getenv("DC_ORO_MQ_URI") == "" {
		mqDsn := fmt.Sprintf("amqp://%s:%s@%s:%s/%%2f",
			os.Getenv("DC_ORO_MQ_USER"),
			os.Getenv("DC_ORO_MQ_PASSWORD"),
			os.Getenv("DC_ORO_MQ_HOST"),
			os.Getenv("DC_ORO_MQ_PORT"))
		os.Setenv("DC_ORO_MQ_URI", mqDsn)
		os.Setenv("ORO_MQ_DSN", mqDsn)
		fmt.Printf("📨 Generated ORO_MQ_DSN: %s\n", mqDsn)
	}

	// Set up Search defaults (Elasticsearch)
	if os.Getenv("DC_ORO_SEARCH_HOST") == "" {
		os.Setenv("DC_ORO_SEARCH_HOST", "search")
	}
	if os.Getenv("DC_ORO_SEARCH_PORT") == "" {
		os.Setenv("DC_ORO_SEARCH_PORT", "9200")
	}

	// Generate Search DSN if not already set
	if os.Getenv("ORO_SEARCH_URL") == "" && os.Getenv("DC_ORO_SEARCH_URI") == "" {
		searchDsn := fmt.Sprintf("elastic-search://%s:%s",
			os.Getenv("DC_ORO_SEARCH_HOST"),
			os.Getenv("DC_ORO_SEARCH_PORT"))
		os.Setenv("DC_ORO_SEARCH_URI", searchDsn)
		os.Setenv("ORO_SEARCH_URL", searchDsn)
		fmt.Printf("🔍 Generated ORO_SEARCH_URL: %s\n", searchDsn)
	}

	// Handle search DSN special case (same as bash version)
	if strings.Contains(os.Getenv("ORO_SEARCH_URL"), "orm:") {
		os.Setenv("DC_ORO_SEARCH_DSN", "")
	} else {
		os.Setenv("DC_ORO_SEARCH_DSN", os.Getenv("ORO_SEARCH_URL"))
	}

	// Set up Redis defaults
	if os.Getenv("DC_ORO_REDIS_HOST") == "" {
		os.Setenv("DC_ORO_REDIS_HOST", "redis")
	}
	if os.Getenv("DC_ORO_REDIS_PORT") == "" {
		os.Setenv("DC_ORO_REDIS_PORT", "6379")
	}

	// Generate Redis DSN if not already set
	if os.Getenv("ORO_REDIS_URL") == "" && os.Getenv("DC_ORO_REDIS_URI") == "" {
		redisDsn := fmt.Sprintf("redis://%s:%s",
			os.Getenv("DC_ORO_REDIS_HOST"),
			os.Getenv("DC_ORO_REDIS_PORT"))
		os.Setenv("DC_ORO_REDIS_URI", redisDsn)
		os.Setenv("ORO_REDIS_URL", redisDsn)
		fmt.Printf("🔴 Generated ORO_REDIS_URL: %s\n", redisDsn)
	}

	// Set ORO_DB_URL if not already set
	if os.Getenv("ORO_DB_URL") == "" {
		var dbUrl string
		if databaseSchema == "mysql" || databaseSchema == "mariadb" {
			dbUrl = fmt.Sprintf("mysql://%s:%s@%s:%s/%s",
				os.Getenv("DC_ORO_DATABASE_USER"),
				os.Getenv("DC_ORO_DATABASE_PASSWORD"),
				os.Getenv("DC_ORO_DATABASE_HOST"),
				os.Getenv("DC_ORO_DATABASE_PORT"),
				os.Getenv("DC_ORO_DATABASE_DBNAME"))
		} else {
			dbUrl = fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
				os.Getenv("DC_ORO_DATABASE_USER"),
				os.Getenv("DC_ORO_DATABASE_PASSWORD"),
				os.Getenv("DC_ORO_DATABASE_HOST"),
				os.Getenv("DC_ORO_DATABASE_PORT"),
				os.Getenv("DC_ORO_DATABASE_DBNAME"))
		}
		os.Setenv("ORO_DB_URL", dbUrl)
		fmt.Printf("🔗 Generated ORO_DB_URL: %s\n", dbUrl)
	}

	return databaseSchema
}

func detectPHPVersionFromProject(projectDir string) {
	// Auto-detect and set PHP version if not already set (following bash version logic)
	if os.Getenv("DC_ORO_PHP_VERSION") != "" {
		return // Already set
	}

	phpVersion := "8.3" // default

	// Check .php-version file first
	phpVersionFile := filepath.Join(projectDir, ".php-version")
	if content, err := os.ReadFile(phpVersionFile); err == nil {
		version := strings.TrimSpace(string(content))
		if version != "" {
			phpVersion = version
			fmt.Printf("🐘 Found .php-version with following version: %s\n", version)
		}
	} else {
		// Check .phprc file
		phprcFile := filepath.Join(projectDir, ".phprc")
		if content, err := os.ReadFile(phprcFile); err == nil {
			version := strings.TrimSpace(string(content))
			if version != "" {
				phpVersion = version
				fmt.Printf("🐘 Found .phprc with following version: %s\n", version)
			}
		} else {
			// Check composer.json for PHP version
			composerFile := filepath.Join(projectDir, "composer.json")
			if content, err := os.ReadFile(composerFile); err == nil {
				// Simple regex to extract PHP version requirement
				re := regexp.MustCompile(`"php":\s*"[^"]*?(\d+\.\d+)`)
				matches := re.FindStringSubmatch(string(content))
				if len(matches) > 1 {
					phpVersion = matches[1]
					fmt.Printf("🐘 Detected PHP version from composer.json: %s\n", phpVersion)
				}
			}
		}
	}

	os.Setenv("DC_ORO_PHP_VERSION", phpVersion)
}

func detectNodeVersionFromProject(projectDir string) {
	// Auto-detect and set Node.js version if not already set
	if os.Getenv("DC_ORO_NODE_VERSION") != "" {
		return // Already set
	}

	nodeVersion := "20" // default

	// Check .nvmrc file
	nvmrcFile := filepath.Join(projectDir, ".nvmrc")
	if content, err := os.ReadFile(nvmrcFile); err == nil {
		version := strings.TrimSpace(string(content))
		if version != "" {
			nodeVersion = version
			fmt.Printf("🟢 Found .nvmrc with following version: %s\n", version)
		}
	}

	os.Setenv("DC_ORO_NODE_VERSION", nodeVersion)
}

// copyComposeFiles copies compose files from Homebrew share to config directory
func copyComposeFiles(configDir string) ([]string, error) {
	// Copy compose/ from Homebrew pkgshare to configDir (only if not exists)
	composeSource := "/opt/homebrew/share/orodc-go/compose" // change if on Intel
	if _, err := os.Stat(configDir); os.IsNotExist(err) {
		fmt.Printf("📦 Copying compose/ files to: %s\n", configDir)
		if err := os.MkdirAll(configDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create config dir: %w", err)
		}
		copyCmd := exec.Command("rsync", "-a", composeSource+"/", configDir+"/")
		copyCmd.Stdout = os.Stdout
		copyCmd.Stderr = os.Stderr
		if err := copyCmd.Run(); err != nil {
			return nil, fmt.Errorf("failed to copy compose files: %w", err)
		}
	}

	// Return the compose files to use
	composeFiles := []string{
		filepath.Join(configDir, "docker-compose.yml"),
		filepath.Join(configDir, "docker-compose-default.yml"),
	}

	return composeFiles, nil
}

func SetupEnvironment() ([]string, error) {
	// Get current directory as project directory
	appDir, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to get current directory: %w", err)
	}

	// Set project name based on directory
	projectName := filepath.Base(appDir)
	os.Setenv("DC_ORO_NAME", projectName)
	os.Setenv("DC_ORO_APPDIR", appDir)

	// Create config directory
	configDir := fmt.Sprintf("%s/.orodc/%s", os.Getenv("HOME"), projectName)
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create config directory: %w", err)
	}
	os.Setenv("DC_ORO_CONFIG_DIR", configDir)

	// Copy compose files
	composeFiles, err := copyComposeFiles(configDir)
	if err != nil {
		return nil, fmt.Errorf("failed to copy compose files: %w", err)
	}

	// Load environment files from project directory (.env-app, .env, etc.)
	if err := loadProjectEnvFiles(appDir); err != nil {
		return nil, fmt.Errorf("failed to load project env files: %w", err)
	}

	// Set up database defaults and parse DSNs
	databaseSchema := setupDatabaseDefaults()

	// Detect and set PHP/Node versions from project
	detectPHPVersionFromProject(appDir)
	detectNodeVersionFromProject(appDir)

	// Set additional environment variables (like bash script)
	setAdditionalEnvVars()

	// Create required Docker network
	if err := createSharedNetwork(); err != nil {
		return nil, fmt.Errorf("failed to create shared network: %w", err)
	}

	// Generate SSH keys if needed
	if err := generateSSHKeys(configDir); err != nil {
		return nil, fmt.Errorf("failed to generate SSH keys: %w", err)
	}

	// Create appcode volume if needed
	if err := createAppcodeVolume(projectName); err != nil {
		return nil, fmt.Errorf("failed to create appcode volume: %w", err)
	}

	// Add database-specific compose file
	if databaseSchema == "mysql" || databaseSchema == "mariadb" {
		composeFiles = append(composeFiles, filepath.Join(configDir, "docker-compose-mysql.yml"))
		fmt.Println("🐬 Using MySQL compose configuration")
	} else {
		composeFiles = append(composeFiles, filepath.Join(configDir, "docker-compose-pgsql.yml"))
		fmt.Println("🗄️ Using PostgreSQL compose configuration")
	}

	// Build compose arguments
	var composeArgs []string
	for _, file := range composeFiles {
		composeArgs = append(composeArgs, "-f", file)
	}

	return append([]string{"compose"}, composeArgs...), nil
}

// createSharedNetwork creates the dc_shared_net network if it doesn't exist (like bash script)
func createSharedNetwork() error {
	networkName := "dc_shared_net"

	// Check if network already exists
	cmd := exec.Command("docker", "network", "ls", "--format", "{{.Name}}")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to list docker networks: %w", err)
	}

	networks := strings.Split(string(output), "\n")
	for _, network := range networks {
		if strings.TrimSpace(network) == networkName {
			fmt.Printf("🌐 Docker network '%s' already exists\n", networkName)
			return nil
		}
	}

	// Create network
	fmt.Printf("🌐 Creating Docker network: %s\n", networkName)
	cmd = exec.Command("docker", "network", "create", networkName)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create network %s: %w", networkName, err)
	}

	return nil
}

// generateSSHKeys generates SSH keys if they don't exist (like bash script)
func generateSSHKeys(configDir string) error {
	sshKeyPath := filepath.Join(configDir, "ssh_id_ed25519")

	// Check if SSH key already exists
	if _, err := os.Stat(sshKeyPath); err == nil {
		// Key exists, load public key
		pubKeyPath := sshKeyPath + ".pub"
		pubKeyBytes, err := os.ReadFile(pubKeyPath)
		if err == nil {
			os.Setenv("ORO_SSH_PUBLIC_KEY", strings.TrimSpace(string(pubKeyBytes)))
		}
		return nil
	}

	// Generate SSH key
	fmt.Printf("🔑 Generating SSH key: %s\n", sshKeyPath)
	cmd := exec.Command("ssh-keygen", "-t", "ed25519", "-f", sshKeyPath, "-N", "", "-q")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to generate SSH key: %w", err)
	}

	// Set permissions
	if err := os.Chmod(sshKeyPath, 0600); err != nil {
		return fmt.Errorf("failed to set SSH key permissions: %w", err)
	}

	// Load and set public key
	pubKeyPath := sshKeyPath + ".pub"
	pubKeyBytes, err := os.ReadFile(pubKeyPath)
	if err != nil {
		return fmt.Errorf("failed to read SSH public key: %w", err)
	}
	os.Setenv("ORO_SSH_PUBLIC_KEY", strings.TrimSpace(string(pubKeyBytes)))

	return nil
}

// createAppcodeVolume creates the appcode volume if it doesn't exist (like bash script)
func createAppcodeVolume(projectName string) error {
	volumeName := fmt.Sprintf("%s_appcode", projectName)

	// Check if volume already exists
	cmd := exec.Command("docker", "volume", "ls", "--format", "{{.Name}}")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to list docker volumes: %w", err)
	}

	volumes := strings.Split(string(output), "\n")
	for _, volume := range volumes {
		if strings.TrimSpace(volume) == volumeName {
			fmt.Printf("📦 Docker volume '%s' already exists\n", volumeName)
			return nil
		}
	}

	// Create volume
	fmt.Printf("📦 Creating Docker volume: %s\n", volumeName)
	cmd = exec.Command("docker", "volume", "create", volumeName)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create volume %s: %w", volumeName, err)
	}

	return nil
}

// setAdditionalEnvVars sets additional environment variables like the bash script
func setAdditionalEnvVars() {
	// Set user information
	userName := os.Getenv("DC_ORO_USER_NAME")
	if userName == "" {
		userName = "developer"
		os.Setenv("DC_ORO_USER_NAME", userName)
	}

	userGroup := os.Getenv("DC_ORO_USER_GROUP")
	if userGroup == "" {
		userGroup = "developer"
		os.Setenv("DC_ORO_USER_GROUP", userGroup)
	}

	// Set UIDs
	if os.Getenv("DC_ORO_USER_UID") == "" {
		os.Setenv("DC_ORO_USER_UID", "1000")
	}
	if os.Getenv("DC_ORO_USER_GID") == "" {
		os.Setenv("DC_ORO_USER_GID", "1000")
	}

	// Export PHP user variables (like bash script)
	os.Setenv("DC_ORO_PHP_USER_NAME", userName)
	os.Setenv("DC_ORO_PHP_USER_GROUP", userGroup)
	os.Setenv("DC_ORO_PHP_USER_UID", os.Getenv("DC_ORO_USER_UID"))
	os.Setenv("DC_ORO_PHP_USER_GID", os.Getenv("DC_ORO_USER_GID"))

	// Set mode (mutagen on macOS, default otherwise)
	if os.Getenv("DC_ORO_MODE") == "" {
		if strings.Contains(strings.ToLower(runtime.GOOS), "darwin") {
			os.Setenv("DC_ORO_MODE", "mutagen")
		} else {
			os.Setenv("DC_ORO_MODE", "default")
		}
	}

	// Set composer version if not set
	if os.Getenv("DC_ORO_COMPOSER_VERSION") == "" {
		os.Setenv("DC_ORO_COMPOSER_VERSION", "2")
	}

	// Set PHP distribution if not set
	if os.Getenv("DC_ORO_PHP_DIST") == "" {
		os.Setenv("DC_ORO_PHP_DIST", "alpine")
	}
}

func EnsureDatabaseReady(composeArgs []string) error {
	databaseSchema := os.Getenv("DC_ORO_DATABASE_SCHEMA")
	if databaseSchema == "" {
		databaseSchema = "pgsql" // default
	}

	// Ensure database exists
	ensureDatabaseExists(composeArgs, databaseSchema)
	return nil
}

func CleanupOrphans(composeArgs []string) error {
	// Clean up orphan containers and volumes for fresh start
	fmt.Println("🧹 Cleaning up orphan containers and volumes...")
	cleanupArgs := append(composeArgs, "down", "--remove-orphans", "-v")
	cleanupCmd := exec.Command("docker", cleanupArgs...)
	cleanupCmd.Stdout = os.Stdout
	cleanupCmd.Stderr = os.Stderr
	return cleanupCmd.Run()
}
