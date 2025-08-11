package objects

import (
	"TowberGoServer/pkg/packets"
	"fmt"
	"math"
	"sync"
	"time"
)

var BattleManager *BattleManagerStruct = &BattleManagerStruct{rooms: make(map[uint32]*BattleRoom)}

type BattleManagerStruct struct {
	rooms    map[uint32]*BattleRoom
	roomLock sync.Mutex
	id       uint32
}

func (b *BattleManagerStruct) CreateRoom(players [2]BattlePlayer) *BattleRoom {
	b.roomLock.Lock()
	defer b.roomLock.Unlock()
	b.id += 1
	room := BattleRoom{
		ID:            b.id,
		Players:       players,
		round:         0,
		NextRoundChan: make(chan int),
		CommandChan:   make(chan *Command),
	}
	b.rooms[b.id] = &room
	go room.Start()
	return &room
}

func (b *BattleManagerStruct) DeleteRoom(id uint32) {
	b.roomLock.Lock()
	defer b.roomLock.Unlock()
	delete(b.rooms, id)
}

type BattleRoom struct {
	ID            uint32
	Players       [2]BattlePlayer
	ready         [2]bool
	round         int
	NextRoundChan chan int
	CommandChan   chan *Command
	End           bool
}

func (r *BattleRoom) GetTheOtherPlayer(num int) int {
	if num == 0 {
		return 1
	} else {
		return 0
	}
}

// SendEvent 发送事件
// 1、进入战斗 2、新回合开始 3、回合结束 4、受伤 5、获得负面buff 6、获得正面buff 7、死亡
func (r *BattleRoom) SendEvent(event int, target int) {
	r.GetEvent(event, target)

	for i, v := range r.Players {
		self := target == i
		for _, k := range v.EquippedPets() {
			if k.Pet == nil {
				continue
			}
			k.GetEvent(event, self, r)
		}
	}
}

func (r *BattleRoom) GetEvent(event int, target int) {
	if event == 7 {
		// 当宠物死亡后，检查是否全部阵亡
		end := true
		for _, v := range r.Players[target].EquippedPets() {
			if v.Pet != nil && v.Stats().HP != 0 {
				end = false
			}
		}
		if end {
			r.EndBattle(r.GetTheOtherPlayer(target))
			return
		}

		r.Players[target].ProcessMessage(&packets.BattlePacket_ChangePetRequest{})
		timer := time.After(10 * time.Second)
		for {
			select {
			case cmd := <-r.CommandChan:
				// 判断是否是目标玩家且是更换宠物指令
				if cmd.Number == target {
					if changeCmd, ok := cmd.Msg.Command.(*packets.RoundCommandMessage_ChangePet); ok {
						pet := r.Players[target].EquippedPets()[changeCmd.ChangePet.PetPosition]
						if pet != nil && pet.Stats().HP > 0 {
							r.Players[target].SetCurrentPet(pet)
							return
						} else {
							deny := &packets.BattlePacket_DenyCommand{DenyCommand: &packets.DenyCommandMessage{Reason: "pet error"}}
							r.Players[cmd.Number].ProcessMessage(deny)
						}
					}
				}
			case <-timer:
				// 超时自动选择一个存活宠物
				for _, pet := range r.Players[target].EquippedPets() {
					if pet != nil && pet.Stats().HP > 0 {
						r.Players[target].SetCurrentPet(pet)
						return
					}
				}
				r.EndBattle(r.GetTheOtherPlayer(target))
			}
		}
	}
}

func (r *BattleRoom) Start() {
	defer func() {
		close(r.NextRoundChan)
		close(r.CommandChan)
		BattleManager.DeleteRoom(r.ID)
		fmt.Println("stop room...")
	}()
	r.Players[0].SetBattleRoom(r)
	r.Players[1].SetBattleRoom(r)

	// 同步双方的信息
	r.SyncPlayerInformation(0)
	r.SyncPlayerInformation(1)

	r.SendEvent(1, 0)
	for {
		r.SendEvent(2, 0)
		r.ready[0], r.ready[1] = false, false
		fmt.Println("开启新回合")
		// 发送下一回合通知
		nextRound := &packets.BattlePacket_StartNextRound{StartNextRound: &packets.StartNextRoundMessage{}}
		for _, v := range r.Players {
			v.ProcessMessage(nextRound)
		}

		fmt.Println("等待指令")
		// 启动回合，等待玩家的指令
		commands := r.WaitCommand()

		fmt.Println("处理指令")
		// 处理指令
		r.ProcessCommand(commands)

		// 检查战斗是否结束
		if r.End {
			return
		}

		// 当前回合已经结束
		roundEnd := packets.BattlePacket_RoundEnd{RoundEnd: &packets.RoundEndMessage{}}
		for _, v := range r.Players {
			v.ProcessMessage(&roundEnd)
		}

		fmt.Println("等待下一回合")
		// 等待玩家请求下一回合
		r.WaitNextRound()

		r.round++
		r.SendEvent(3, 0)
	}
}

func (r *BattleRoom) SyncPlayerInformation(number int) {
	petMessages := make([]*packets.PetMessage, 5)
	for i, v := range r.Players[number].EquippedPets() {
		if v == nil {
			continue
		}
		petMessages[i] = newPetMessage(v.Pet)
	}
	msg := packets.SyncBattleInformationMessage{
		Number:      int64(number),
		PlayerName:  r.Players[number].UserName(),
		PetMessages: petMessages,
	}
	r.Players[0].ProcessMessage(&packets.BattlePacket_SyncBattleInformation{SyncBattleInformation: &msg})
	r.Players[1].ProcessMessage(&packets.BattlePacket_SyncBattleInformation{SyncBattleInformation: &msg})
}

func (r *BattleRoom) WaitNextRound() {
	for {
		select {
		case num := <-r.NextRoundChan:
			r.ready[num] = true
			if r.ready[0] == true && r.ready[1] == true {
				return
			}
		}
	}
}

// EndBattle 结束战斗，销毁房间，发送战斗统计信息
func (r *BattleRoom) EndBattle(winner int) {
	r.End = true
	msg := &packets.BattlePacket_BattleEnd{BattleEnd: &packets.BattleEndMessage{Winner: int64(winner)}}
	for _, v := range r.Players {
		v.ProcessMessage(msg)
	}
}

func (r *BattleRoom) WaitCommand() [2]*Command {
	commands := [2]*Command{}
	valid := [2]bool{}
	timer := time.After(15 * time.Second)
	for {
		select {
		case cmd := <-r.CommandChan:
			if r.isValid(cmd) && valid[cmd.Number] == false {
				commands[cmd.Number] = cmd
				valid[cmd.Number] = true
			} else {
				deny := &packets.BattlePacket_DenyCommand{DenyCommand: &packets.DenyCommandMessage{Reason: "command error"}}
				r.Players[cmd.Number].ProcessMessage(deny)
			}
			if valid[0] && valid[1] {
				return commands
			}
		case <-timer:
			return commands
		}
	}
}

func (r *BattleRoom) isValid(command *Command) bool {
	switch cmd := command.Msg.Command.(type) {
	case *packets.RoundCommandMessage_ChangePet:
		if r.Players[command.Number].EquippedPets()[cmd.ChangePet.PetPosition] != nil {
			return true
		} else {
			return false
		}
	}
	return true
}

func (r *BattleRoom) ProcessCommand(commands [2]*Command) {
	skills := [2]Skill{}
	for i := range commands {
		if commands[i] == nil {
			continue
		}
		switch command := commands[i].Msg.Command.(type) {
		case *packets.RoundCommandMessage_Attack:
			skill := r.Players[i].CurrentPet().EquippedSkills()[command.Attack.SkillPos]
			skills[i] = skill
		case *packets.RoundCommandMessage_Runaway:
			r.EndBattle(r.GetTheOtherPlayer(commands[i].Number))
			return
		case *packets.RoundCommandMessage_ChangePet:
			pet := r.Players[i].EquippedPets()[command.ChangePet.PetPosition]
			r.Players[i].SetCurrentPet(pet)
		}
	}

	// 处理技能
	if skills[0] != nil && skills[1] != nil {
		first, second := 0, 1
		// 比较速度
		if skills[0].Speed() < skills[1].Speed() {
			first, second = 1, 0
		} else if skills[0].Speed() == skills[1].Speed() {
			if r.Players[0].CurrentPet().Stats().Speed < r.Players[1].CurrentPet().Stats().Speed {
				first, second = 1, 0
			}
		}

		attack0 := skills[first].Use(r.Players[first].CurrentPet(), r.Players[second].CurrentPet())
		for _, v := range attack0 {
			v.From = r.Players[first].CurrentPet()
			v.To = r.Players[second].CurrentPet()
			r.ProcessAttackInfo(v, first, second)
		}

		attack1 := skills[second].Use(r.Players[second].CurrentPet(), r.Players[first].CurrentPet())
		for _, v := range attack1 {
			v.From = r.Players[first].CurrentPet()
			v.To = r.Players[second].CurrentPet()
			r.ProcessAttackInfo(v, second, first)
		}
	} else {
		for i, v := range skills {
			if v != nil {
				attack := skills[i].Use(r.Players[i].CurrentPet(), r.Players[r.GetTheOtherPlayer(i)].CurrentPet())
				for _, k := range attack {
					k.From = r.Players[i].CurrentPet()
					k.To = r.Players[r.GetTheOtherPlayer(i)].CurrentPet()
					r.ProcessAttackInfo(k, i, r.GetTheOtherPlayer(i))
				}
			}
		}
	}
}

func (r *BattleRoom) ProcessAttackInfo(info *AttackInfo, from int, to int) {
	fromPet := r.Players[from].CurrentPet()
	toPet := r.Players[to].CurrentPet()
	if fromPet == nil || toPet == nil {
		return
	}

	// 自身加成
	info.PhysicalDamage = int(float64(info.PhysicalDamage) * (1 + float64(fromPet.Stats().Strength)*0.01))
	info.MagicDamage = int(float64(info.MagicDamage) * (1 + float64(fromPet.Stats().Intelligence)*0.01))
	// TODO 处理buff

	// 敌方加成
	info.PhysicalDamage = int(float64(info.PhysicalDamage) * (1 - float64(toPet.Stats().Strength)*0.01))
	info.MagicDamage = int(float64(info.MagicDamage) * (1 - float64(toPet.Stats().Intelligence)*0.01))
	// TODO 处理buff

	// 应用
	toPet.Stats().HP = int(math.Max(0, float64(toPet.Stats().HP-info.PhysicalDamage-info.MagicDamage)))

	// 发送消息
	petStats := make([]*packets.PetStatsMessage, 2)
	for i := 0; i < 2; i++ {
		s := r.Players[i].CurrentPet().Stats()
		petStats[i] = &packets.PetStatsMessage{
			MaxHp:        int64(s.MaxHP),
			Hp:           int64(s.HP),
			MaxMana:      int64(s.MaxMana),
			Mana:         int64(s.Mana),
			Strength:     int64(s.Strength),
			Intelligence: int64(s.Intelligence),
			Speed:        int64(s.Speed),
			Defense:      int64(s.Defense),
		}
	}
	attackStats := packets.AttackStatsMessage{
		Number:         int64(from),
		SkillId:        info.Skill,
		PhysicalDamage: int64(info.PhysicalDamage),
		MagicDamage:    int64(info.MagicDamage),
		// TODO 传递buff
		Buffs:    nil,
		PetStats: petStats,
	}
	r.Players[0].ProcessMessage(&packets.BattlePacket_AttackStats{AttackStats: &attackStats})
	r.Players[1].ProcessMessage(&packets.BattlePacket_AttackStats{AttackStats: &attackStats})

	if toPet.Stats().HP <= 0 {
		r.SendEvent(7, to)
	}
}

type BattlePlayer interface {
	ProcessMessage(message packets.BattleMsg)
	CurrentPet() *BattlePet
	SetCurrentPet(pet *BattlePet)
	EquippedPets() [5]*BattlePet
	SetBattleRoom(room *BattleRoom)
	UserName() string
}

type BattlePet struct {
	Pet
	Buffs []Buff
}

type AttackInfo struct {
	Skill          uint32
	From           *BattlePet
	To             *BattlePet
	PhysicalDamage int
	MagicDamage    int
	BuffDamage     []*BuffDamage
	PetStats       [2]Stats
}

type BuffDamage struct {
	ID    int
	Level int
}

type Buff interface {
	ID() int
	Update(updateLevel int)
	SetPet(pet *BattlePet)
	Use(attack *AttackInfo)
	IsPositive() bool
}

// BattleEndStats 战斗结束后的统计数据
type BattleEndStats struct {
}

type Command struct {
	Msg    *packets.RoundCommandMessage
	Number int
}

func (r *BattleRoom) ReplacePlayerAuto(number int) {
	r.Players[number] = &AutoBattlePlayer{CommandChan: r.CommandChan, NextRoundChan: r.NextRoundChan}
	r.NextRoundChan <- number
}

type AutoBattlePlayer struct {
	Number        int
	CommandChan   chan *Command
	NextRoundChan chan int
}

func (a *AutoBattlePlayer) ProcessMessage(message packets.BattleMsg) {
	switch message.(type) {
	case *packets.BattlePacket_StartNextRound:
		// 自动输入逃跑指令
		cmd := &Command{
			Msg: &packets.RoundCommandMessage{
				Command: &packets.RoundCommandMessage_Runaway{},
			},
			Number: a.Number,
		}
		a.CommandChan <- cmd
	}
	// 其它消息不处理
}

func (a *AutoBattlePlayer) CurrentPet() *BattlePet {
	return nil
}

func (a *AutoBattlePlayer) SetCurrentPet(pet *BattlePet) {
	// 不做任何操作
}

func (a *AutoBattlePlayer) EquippedPets() [5]*BattlePet {
	return [5]*BattlePet{}
}

func (a *AutoBattlePlayer) SetBattleRoom(room *BattleRoom) {

}

func (a *AutoBattlePlayer) UserName() string {
	return "auto battle"
}

func newPetMessage(pet Pet) *packets.PetMessage {
	res := packets.PetMessage{}
	if pet == nil {
		return nil
	}
	res.PetId = pet.PetID()
	res.Id = pet.ID()
	res.Exp = int64(pet.Exp())
	res.Level = int64(pet.Level())
	equippedSkills := make([]uint32, 4)
	for a, b := range pet.EquippedSkills() {
		if b == nil {
			continue
		}
		equippedSkills[a] = uint32(b.ID())
	}
	stats := packets.PetStatsMessage{
		MaxHp:        int64(pet.Stats().MaxHP),
		Hp:           int64(pet.Stats().HP),
		MaxMana:      int64(pet.Stats().MaxMana),
		Mana:         int64(pet.Stats().Mana),
		Strength:     int64(pet.Stats().Strength),
		Intelligence: int64(pet.Stats().Intelligence),
		Speed:        int64(pet.Stats().Speed),
		Defense:      int64(pet.Stats().Defense),
	}
	res.EquippedSkills = equippedSkills
	res.PetStats = &stats
	return &res
}
