package logger

import (
	"fmt"
	"log"
	"os"
	"strings"
)

// LogLevel represents the logging level
type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARN
	ERROR
	FATAL
)

// Logger provides structured logging for the Septica backend
type Logger struct {
	level LogLevel
}

// New creates a new logger with the specified level
func New(levelStr string) *Logger {
	level := parseLogLevel(strings.ToLower(levelStr))
	return &Logger{level: level}
}

// parseLogLevel converts a string to LogLevel
func parseLogLevel(levelStr string) LogLevel {
	switch levelStr {
	case "debug":
		return DEBUG
	case "info":
		return INFO
	case "warn", "warning":
		return WARN
	case "error":
		return ERROR
	case "fatal":
		return FATAL
	default:
		return INFO
	}
}

// Debug logs a debug message
func (l *Logger) Debug(msg string, args ...interface{}) {
	if l.level <= DEBUG {
		l.log("DEBUG", msg, args...)
	}
}

// Info logs an info message
func (l *Logger) Info(msg string, args ...interface{}) {
	if l.level <= INFO {
		l.log("INFO", msg, args...)
	}
}

// Warn logs a warning message
func (l *Logger) Warn(msg string, args ...interface{}) {
	if l.level <= WARN {
		l.log("WARN", msg, args...)
	}
}

// Error logs an error message
func (l *Logger) Error(msg string, args ...interface{}) {
	if l.level <= ERROR {
		l.log("ERROR", msg, args...)
	}
}

// Fatal logs a fatal message and exits the program
func (l *Logger) Fatal(msg string, args ...interface{}) {
	l.log("FATAL", msg, args...)
	os.Exit(1)
}

// log is the internal logging method
func (l *Logger) log(level, msg string, args ...interface{}) {
	// Simple structured logging - in production, consider using a more sophisticated logger
	logMsg := "[" + level + "] " + msg

	// Add key-value pairs if provided
	for i := 0; i < len(args); i += 2 {
		if i+1 < len(args) {
			logMsg += " " + args[i].(string) + "=" + formatValue(args[i+1])
		}
	}

	log.Println(logMsg)
}

// formatValue formats a value for logging
func formatValue(v interface{}) string {
	switch val := v.(type) {
	case string:
		return val
	case error:
		return val.Error()
	default:
		return fmt.Sprintf("%v", val)
	}
}

// WithFields creates a new logger with additional fields (for future enhancement)
func (l *Logger) WithFields(fields map[string]interface{}) *Logger {
	// For now, just return the same logger
	// In a production system, you might want to implement field storage
	return l
}
