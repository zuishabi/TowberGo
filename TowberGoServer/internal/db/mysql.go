package db

import (
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"time"
)

const dsn string = "root:861214959@tcp(127.0.0.1:3306)/game?charset=utf8mb4&parseTime=True&loc=Asia%2FShanghai"

func NewDb() (*gorm.DB, error) {
	return gorm.Open(mysql.Open(dsn), &gorm.Config{})
}

func UpdateStructs(db *gorm.DB) error {
	if err := db.AutoMigrate(&UserInfo{}); err != nil {
		return err
	}
	return nil
}

type UserInfo struct {
	ID        uint32 `gorm:"primaryKey"`
	CreatedAt time.Time
	UserName  string `gorm:"Index"`
	Password  string
}
