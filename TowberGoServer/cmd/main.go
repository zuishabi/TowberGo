package main

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/clients"
	"TowberGoServer/internal/game/areas"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/list"
	"flag"
	"fmt"
	"github.com/joho/godotenv"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

type config struct {
	Port int
	Cert string
	Key  string
}

var (
	defaultConfig = &config{Port: 8080}
	configPath    = flag.String("config", ".env", "Path to the config file")
)

func loadConfig() *config {
	cfg := defaultConfig
	cfg.Cert = os.Getenv("CERT_PATH")
	cfg.Key = os.Getenv("KEY_PATH")

	port, err := strconv.Atoi(os.Getenv("PORT"))
	if err != nil {
		log.Printf("Error parsing PORT,using %d", cfg.Port)
		return cfg
	}
	cfg.Port = port
	return cfg
}

func main() {
	flag.Parse()
	err := godotenv.Load(*configPath)
	cfg := defaultConfig
	if err != nil {
		log.Printf("Error loading config file,defaulting to %+v", defaultConfig)
	} else {
		cfg = loadConfig()
	}
	exportPath := "C:\\projects\\TowberGo\\TowberGoServer\\shared\\export"
	if _, err := os.Stat(exportPath); err != nil {
		if !os.IsNotExist(err) {
			log.Fatalf("Error checking for HTML5 export: %v", err)
		}
	} else {
		log.Printf("Serving HTML5 export from %s", exportPath)
		http.Handle("/", addHeaders(http.StripPrefix("/", http.FileServer(http.Dir(exportPath)))))
	}
	// 定义hub
	hub := internal.NewHub()

	// 创建areaMgr并进行初始化
	objects.AreaMgr = objects.NewAreaMgr(hub, []objects.Area{
		&areas.InitialVillage{}, &areas.AdventureHub{},
	})
	objects.AreaMgr.Initialize()

	// 创建itemManager并进行初始化
	objects.ItemManager = &objects.ItemManagerStruct{ItemMap: list.ItemList}

	// 创建petItemManager 并进行初始化
	objects.PetItemManager = &objects.PetItemManagerStruct{PetItemList: list.PetItemList}

	// 创建petManager并进行初始化
	objects.PetManager = objects.NewPetManager(hub.Db, list.PetList)
	go objects.PetManager.SavePetGoroutine(hub)

	// 创建SkillManager并进行初始化
	objects.SkillManager = &objects.SkillManagerStruct{SkillList: list.SkillsList}

	// 创建LootManager并进行初始化
	objects.LootManager = &objects.LootManagerStruct{}

	// 定义websocket处理
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})
	go hub.Run()
	addr := fmt.Sprintf(":%d", cfg.Port)
	log.Printf("Starting server on %s", addr)
	//err = http.ListenAndServeTLS(addr, cfg.Cert, cfg.Key, nil)
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatalf("failed to start server:%v", err)
	}
}

func addHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, ".wasm") {
			w.Header().Set("Content-Type", "application/wasm")
		}
		w.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
		w.Header().Set("Cross-Origin-Embedder-Policy", "require-corp")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		next.ServeHTTP(w, r)
	})
}
