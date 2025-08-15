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
	if err := db.AutoMigrate(&Pets{}); err != nil {
		return err
	}
	if err := db.AutoMigrate(&PetSkills{}); err != nil {
		return err
	}
	if err := db.AutoMigrate(&PetStats{}); err != nil {
		return err
	}
	if err := db.AutoMigrate(&EquippedPets{}); err != nil {
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

type Pets struct {
	ID        uint64 `gorm:"primaryKey"`
	PetID     uint32
	CreatedAt time.Time
	Owner     uint32 `gorm:"Index"`
	Exp       int
}

type PetSkills struct {
	ID    uint64 `gorm:"primaryKey"`
	Slot1 uint32
	Slot2 uint32
	Slot3 uint32
	Slot4 uint32
}

type PetStats struct {
	ID           uint64 `gorm:"primaryKey"`
	MaxHP        int
	HP           int
	MaxMana      int
	Mana         int
	Strength     int
	Intelligence int
	Speed        int
	Defense      int
}

type EquippedPets struct {
	UID   uint32 `gorm:"primaryKey"`
	Slot1 uint64
	Slot2 uint64
	Slot3 uint64
	Slot4 uint64
	Slot5 uint64
}

type PlayerTaskProgress struct {
	PlayerID   int64  `gorm:"primaryKey"`
	TaskID     int    `gorm:"primaryKey"`
	Status     int    // 0=未开始, 1=进行中, 2=已完成, 3=已领取奖励
	Progress   string // JSON格式的进度数据
	StartTime  time.Time
	UpdateTime time.Time
}
