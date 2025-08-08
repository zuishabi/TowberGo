package objects

import (
	"TowberGoServer/pkg/packets"
	"time"
)

type BattleManagerStruct struct {
}

type BattleRoom struct {
	ID            uint32
	Players       [2]BattlePlayer
	ready         [2]bool
	round         int
	NextRoundChan chan int
	CommandChan   chan *Command
}

// SendEvent 发送事件
func (r *BattleRoom) SendEvent(event int, target int) {
	players := [2]bool{false, false}
	if event == 1 || event == 2 || event == 3 {
		players[0] = true
		players[1] = true
	} else {
		players[target] = true
	}

	for i, v := range players {
		if v == true {
			for _, k := range r.Players[i].EquippedPets() {
				if k.Stats().HP != 0 {
					k.GetEvent(event, i, r)
				}
			}
		}
	}
}

func (r *BattleRoom) Start() {
	r.SendEvent(1, 0)
	for {
		r.SendEvent(2, 0)
		r.ready[0], r.ready[1] = false, false
		// TODO 发送下一回合通知

		// 启动回合，等待玩家的指令
		commands := r.WaitCommand()

		// 处理指令
		r.ProcessCommand(commands)

		// 等待玩家请求下一回合
		r.WaitNextRound()
		if r.CheckBattleEnd() {
			break
		}
		r.round++
		r.SendEvent(3, 0)
	}

	// TODO 进行战斗结束统计
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

func (r *BattleRoom) CheckBattleEnd() bool {
	// TODO 检查战斗是否结束
	return true
}

// EndBattle 结束战斗，销毁房间，发送战斗统计信息
func (r *BattleRoom) EndBattle() {
	// TODO 结束战斗
}

func (r *BattleRoom) WaitCommand() [2]*Command {
	commands := [2]*Command{}
	valid := [2]bool{}
	timer := time.After(15 * time.Second)
	for {
		select {
		case cmd := <-r.CommandChan:
			if r.isValid(cmd) { // 你需要实现 isValid 校验函数
				commands[cmd.Number] = cmd
				valid[cmd.Number] = true
			} else {
				// TODO 通知玩家指令有误
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
		switch command := commands[i].Msg.Command.(type) {
		case *packets.RoundCommandMessage_Attack:
			skill := r.Players[i].CurrentPet().EquippedSkills()[command.Attack.SkillPos]
			skills[i] = skill
		case *packets.RoundCommandMessage_Runaway:
			return
		case *packets.RoundCommandMessage_ChangePet:
			pet := r.Players[i].EquippedPets()[command.ChangePet.PetPosition]
			r.Players[i].SetCurrentPet(pet)
		}
	}

	// 处理技能
	if skills[0] != nil && skills[1] != nil {
		// 比较速度
		if skills[0].Speed() > skills[1].Speed() {

			r.ProcessAttackInfo(skills[0].Use(r.Players[0].CurrentPet(), r.Players[1].CurrentPet()))

			r.ProcessAttackInfo(skills[1].Use(r.Players[1].CurrentPet(), r.Players[0].CurrentPet()))
		}
	}
}

func (r *BattleRoom) ProcessAttackInfo(infos []*AttackInfo) {
	// 自身加成
	// 敌方加成
	// 发送结果
}

type BattlePlayer interface {
	ProcessMessage(message packets.Msg)
	CurrentPet() *BattlePet
	SetCurrentPet(pet *BattlePet)
	EquippedPets() [4]*BattlePet
}

type BattlePet struct {
	Pet
	Buffs []Buff
}

type AttackInfo struct {
	From           *BattlePet
	PhysicalDamage int
	MagicDamage    int
	BuffDamage     []*BuffDamage
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

// AttackStats 宠物使用一次技能时发送的统计数据
type AttackStats struct {
	SkillID uint32
}

// PetStats 同步宠物状态
type PetStats struct {
	Stats          Stats
	SkillsCoolDown [4]int
	Buffs          []Buff
}

type Command struct {
	Msg    *packets.RoundCommandMessage
	Number int
}
