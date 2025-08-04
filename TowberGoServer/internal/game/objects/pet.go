package objects

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/db"
	"TowberGoServer/pkg/packets"
	"fmt"
	"gorm.io/gorm"
	"time"
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

//--------------------------------------------------宠物管理--------------------------------------------------------------

var PetManager *PetManagerStruct

// PetManagerStruct 管理用户宠物背包，所有和数据库交互的地方都要通过这个管理器
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

func (p *PetManagerStruct) GetPetTemplate(id uint32) Pet {
	return p.petList[id]
}

// SavePet 给玩家的宠物进行信息更新
func (p *PetManagerStruct) SavePet(player *Player, pet Pet) {
	// 首先保存基本信息
	data := &db.Pets{
		Exp: pet.Exp(),
	}
	player.Client.Db().Model(&db.Pets{}).Where("id = ?", pet.ID()).Update("exp", data.Exp)

	// 保存数据信息
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
	player.Client.Db().Model(&db.PetStats{}).Where("id = ?", pet.ID()).Updates(stats)

	// 保存技能配置信息
	equippedSkills := db.PetSkills{}
	list := pet.EquippedSkills()
	equippedSkills.Slot1 = uint32(list[0].ID())
	equippedSkills.Slot2 = uint32(list[1].ID())
	equippedSkills.Slot3 = uint32(list[2].ID())
	equippedSkills.Slot4 = uint32(list[3].ID())
	p.db.Model(&db.PetSkills{}).Where("id = ?", pet.ID()).Updates(&equippedSkills)
}

// CreatePet 向玩家添加一个新宠物，并返回是否放入到背包中
func (p *PetManagerStruct) CreatePet(player *Player, petID uint32) (Pet, bool) {
	pet := p.petList[petID].Initialize(0, nil, nil, player)
	data := &db.Pets{
		PetID: petID,
		Owner: player.UID,
		Exp:   0,
	}
	equipped := false
	p.db.Create(data)
	pet.SetID(data.ID)

	// 创建宠物状态
	s := pet.Stats()
	stats := &db.PetStats{
		ID:           pet.ID(),
		MaxHP:        s.MaxHP,
		HP:           s.HP,
		Strength:     s.Strength,
		Intelligence: s.Intelligence,
		Speed:        s.Speed,
		Defense:      s.Defense,
	}
	p.db.Create(stats)

	// 创建宠物技能
	t := pet.EquippedSkills()
	skills := &db.PetSkills{
		ID: pet.ID(),
	}
	if t[0] != nil {
		skills.Slot1 = uint32(t[0].ID())
	}
	if t[1] != nil {
		skills.Slot2 = uint32(t[1].ID())
	}
	if t[2] != nil {
		skills.Slot3 = uint32(t[2].ID())
	}
	if t[3] != nil {
		skills.Slot4 = uint32(t[3].ID())
	}
	p.db.Create(skills)

	for i, v := range player.EquippedPets {
		if v == nil {
			p.EquipPet(player, pet, i)
			equipped = true
			break
		}
	}

	// 向客户端发送获得宠物的消息
	packet := packets.Packet_GetPet{GetPet: &packets.GetPetMessage{
		Id:       pet.PetID(),
		Equipped: equipped,
	}}
	player.Client.SocketSend(&packet)

	return pet, equipped
}

// GetPetBag 获得宠物背包中的所有宠物
func (p *PetManagerStruct) GetPetBag(player *Player) []Pet {
	equippedPet := db.EquippedPets{}
	p.db.Where("uid = ?", player.UID).First(&equippedPet)
	res := make([]Pet, 5)
	dbPet := db.Pets{}
	if equippedPet.Slot1 != 0 {
		p.db.Where("id = ?", equippedPet.Slot1).First(&dbPet)
		pet1 := p.GetPet(player, dbPet.ID)
		res[0] = pet1
	}
	if equippedPet.Slot2 != 0 {
		p.db.Where("id = ?", equippedPet.Slot2).First(&dbPet)
		pet2 := p.GetPet(player, dbPet.ID)
		res[1] = pet2
	}
	if equippedPet.Slot3 != 0 {
		p.db.Where("id = ?", equippedPet.Slot3).First(&dbPet)
		pet3 := p.GetPet(player, dbPet.ID)
		res[2] = pet3
	}
	if equippedPet.Slot4 != 0 {
		p.db.Where("id = ?", equippedPet.Slot4).First(&dbPet)
		pet4 := p.GetPet(player, dbPet.ID)
		res[3] = pet4
	}
	if equippedPet.Slot5 != 0 {
		p.db.Where("id = ?", equippedPet.Slot5).First(&dbPet)
		pet5 := p.GetPet(player, dbPet.ID)
		res[4] = pet5
	}
	return res
}

func (p *PetManagerStruct) GetPet(player *Player, id uint64) Pet {
	skills := p.GetPetSkill(id)
	stats := p.GetPetStats(id)
	pet := db.Pets{}
	p.db.Where("id = ?", id).First(&pet)
	res := p.petList[pet.PetID].Initialize(pet.Exp, skills, stats, player)
	return res
}

func (p *PetManagerStruct) GetPetSkill(id uint64) []uint32 {
	res := make([]uint32, 4)
	petSkill := db.PetSkills{}
	p.db.Where("id = ?", id).First(&petSkill)
	if petSkill.Slot1 != 0 {
		res[0] = petSkill.Slot1
	}
	if petSkill.Slot2 != 0 {
		res[1] = petSkill.Slot2
	}
	if petSkill.Slot3 != 0 {
		res[2] = petSkill.Slot3
	}
	if petSkill.Slot4 != 0 {
		res[3] = petSkill.Slot4
	}
	return res
}

func (p *PetManagerStruct) GetPetStats(id uint64) *Stats {
	stat := db.PetStats{}
	p.db.Where("id = ?", id).First(&stat)
	return &Stats{
		MaxHP:        stat.MaxHP,
		HP:           stat.HP,
		Strength:     stat.Strength,
		Intelligence: stat.Intelligence,
		Speed:        stat.Speed,
		Defense:      stat.Defense,
	}
}

func (p *PetManagerStruct) SavePetGoroutine(hub *internal.Hub) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			fmt.Println("saving player's pet...")
			hub.BroadCast(&packets.Packet{Msg: &packets.Packet_SavePet{SavePet: &packets.SavePetMessage{}}})
		}
	}
}

func (p *PetManagerStruct) EquipPet(player *Player, pet Pet, position int) {
	player.PetBagLock.Lock()
	defer player.PetBagLock.Unlock()
	if player.EquippedPets[position] != nil {
		p.SavePet(player, player.EquippedPets[position])
	}
	player.EquippedPets[position] = pet
	p.db.Model(&db.EquippedPets{}).Where("uid = ?", player.UID).Update(fmt.Sprintf("slot%d", position+1), pet.ID())
}

func (p *PetManagerStruct) UnequipPet(player *Player, position int) {
	player.PetBagLock.Lock()
	defer player.PetBagLock.Unlock()
	if position <= 4 && player.EquippedPets[position] != nil {
		pet := player.EquippedPets[position]
		for i := position; i < 4; i++ {
			player.EquippedPets[i] = player.EquippedPets[i+1]
		}
		player.EquippedPets[4] = nil
		p.SavePet(player, pet)
	}
	equipped := map[string]interface{}{
		"uid":   player.UID,
		"slot1": player.EquippedPets[0].ID(),
		"slot2": player.EquippedPets[1].ID(),
		"slot3": player.EquippedPets[2].ID(),
		"slot4": player.EquippedPets[3].ID(),
		"slot5": 0,
	}
	p.db.Model(&db.EquippedPets{}).Where("uid = ?", player.UID).Updates(equipped)
}
