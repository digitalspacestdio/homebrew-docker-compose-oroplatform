package config

import (
	"net/url"
	"os"
	"strings"
)

type DSN struct {
	Schema   string
	User     string
	Password string
	Host     string
	Port     string
	DBName   string
	Query    string
	URI      string
}

func ParseDSN(uri, name, prefix string) *DSN {
	if uri == "" || name == "" {
		return nil
	}

	parsed, err := url.Parse(uri)
	if err != nil {
		return nil
	}

	host := parsed.Hostname()
	port := parsed.Port()
	user := ""
	password := ""
	if parsed.User != nil {
		user = parsed.User.Username()
		password, _ = parsed.User.Password()
	}

	dbname := strings.TrimPrefix(parsed.Path, "/")
	query := parsed.RawQuery
	dsn := &DSN{
		Schema:   parsed.Scheme,
		User:     user,
		Password: password,
		Host:     host,
		Port:     port,
		DBName:   dbname,
		Query:    query,
		URI:      uri,
	}

	prefixEnv := strings.ToUpper(prefix + "_" + name)
	os.Setenv(prefixEnv+"_SCHEMA", dsn.Schema)
	os.Setenv(prefixEnv+"_USER", dsn.User)
	os.Setenv(prefixEnv+"_PASSWORD", dsn.Password)
	os.Setenv(prefixEnv+"_HOST", dsn.Host)
	os.Setenv(prefixEnv+"_PORT", dsn.Port)
	os.Setenv(prefixEnv+"_DB_NAME", dsn.DBName)
	os.Setenv(prefixEnv+"_QUERY", dsn.Query)
	os.Setenv(prefixEnv+"_URI", dsn.URI)

	return dsn
}
