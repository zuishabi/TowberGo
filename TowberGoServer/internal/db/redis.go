package db

import (
	"context"
	"fmt"
	"github.com/redis/go-redis/v9"
)

var Rdb *redis.Client

func init() {
	Rdb = redis.NewClient(&redis.Options{
		Addr:     "localhost:6379",
		Password: "861214959",
		DB:       0,
	})
	pong, err := Rdb.Ping(context.Background()).Result()
	if err != nil {
		panic(err)
	}
	fmt.Println(pong)
}
