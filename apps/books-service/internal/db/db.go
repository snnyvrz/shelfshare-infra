package db

import (
	"log"
	"strings"
	"time"

	"github.com/snnyvrz/shelfshare/apps/books-service/internal/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

const (
	defaultMaxAttempts     = 10
	defaultDelayBetweenTry = 2 * time.Second
)

func ConnectWithRetry(cfg *config.Config) *gorm.DB {
	var db *gorm.DB
	var err error

	missing := make([]string, 0, 5)
	if cfg.DBHost == "" {
		missing = append(missing, "DB_HOST")
	}
	if cfg.DBName == "" {
		missing = append(missing, "DB_NAME")
	}
	if cfg.DBUser == "" {
		missing = append(missing, "DB_USER")
	}
	if cfg.DBPass == "" {
		missing = append(missing, "DB_PASS")
	}
	if cfg.DBPort == "" {
		missing = append(missing, "DB_PORT")
	}
	if len(missing) > 0 {
		log.Fatalf("invalid DB config: missing fields: %s", strings.Join(missing, ", "))
	}

	for attempt := 1; attempt <= defaultMaxAttempts; attempt++ {
		db, err = gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{})
		if err == nil {
			sqlDB, err2 := db.DB()
			if err2 == nil {
				pingErr := sqlDB.Ping()
				if pingErr == nil {
					return db
				}
				err = pingErr
			} else {
				err = err2
			}
		}

		log.Printf("db not ready (attempt %d/%d): %v", attempt, defaultMaxAttempts, err)
		time.Sleep(defaultDelayBetweenTry)
	}

	log.Fatalf("could not connect to db after %d attempts: %v", defaultMaxAttempts, err)
	return nil
}
