package objects

import (
	"TowberGoServer/internal/db"
	"gorm.io/gorm"
	"strconv"
)

type Pet interface {
	// PetID 宠物id
	PetID() uint32
	// ID 每个宠物的编号
	ID() uint64
	// SetID 设置宠物的编号
	SetID(id uint64)
	Name() string
	SkillList() map[int]Skill
	Exp() int
	AddExp(exp int) bool
	Level() int
	UnlockedSkillList() []Skill
	EquippedSkills() []Skill
	Initialize(exp int, equippedSkills []uint32, stats *Stats, owner *Player) Pet
	Stats() *Stats
	BaseStats() Stats
	// LevelUp 宠物提升一级时调用
	LevelUp()
	Owner() *Player
}

type Stats struct {
	MaxHP        int
	HP           int
	Strength     int
	Intelligence int
	Speed        int
	Defense      int
}

var MaxExp = 320
var LevelList = []int{
	20, 40, 80, 160, 320,
}

func ConvertExpToLevel(exp int) int {
	for i := range LevelList {
		if exp < LevelList[i] {
			return i + 1
		}
	}
	return len(LevelList) + 1
}

var PetManager *PetManagerStruct

type PetManagerStruct struct {
	db      *gorm.DB
	petList map[uint32]Pet
}

func NewPetManager(db *gorm.DB, petList map[uint32]Pet) *PetManagerStruct {
	return &PetManagerStruct{
		db:      db,
		petList: petList,
	}
}

func (p *PetManagerStruct) GetPet(id uint32) Pet {
	return p.petList[id]
}

// SavePet 给玩家的宠物进行信息更新
func (p *PetManagerStruct) SavePet(player *Player, pet Pet) {
	data := &db.Pets{
		Exp: pet.Exp(),
	}
	player.Client.Db().Model(&db.Pets{}).Where("id = ?", pet.ID()).Update("exp", data.Exp)
	s := pet.Stats()
	stats := map[string]interface{}{
		"id":           pet.ID(),
		"max_hp":       s.MaxHP,
		"hp":           s.HP,
		"strength":     s.Strength,
		"intelligence": s.Intelligence,
		"speed":        s.Speed,
		"defense":      s.Defense,
	}
	player.Client.Db().Updates(stats)
}

// CreatePet 向玩家添加一个新宠物，并返回是否放入到背包中
func (p *PetManagerStruct) CreatePet(player *Player, petID uint32) (Pet, bool) {
	pet := p.petList[petID].Initialize(0, nil, nil, player)
	equip := &db.EquippedPets{}
	data := &db.Pets{
		PetID:    petID,
		Owner:    player.UID,
		Exp:      0,
		Equipped: true,
	}
	player.PetBagLock.Lock()
	defer player.PetBagLock.Unlock()
	p.db.Where("id = ?", player.UID).First(equip)
	slot := -1
	if equip.Slot1 == 0 {
		slot = 1
	} else if equip.Slot2 == 0 {
		slot = 2
	} else if equip.Slot3 == 0 {
		slot = 3
	} else if equip.Slot4 == 0 {
		slot = 4
	} else if equip.Slot5 == 0 {
		slot = 5
	} else {
		data.Equipped = false
	}
	p.db.Create(data)
	pet.SetID(data.ID)
	if data.Equipped {
		p.db.Model(&db.EquippedPets{}).Where("id = ?", player.UID).Update("slot_"+strconv.Itoa(slot), data.ID)
	}
	return pet, data.Equipped
}
