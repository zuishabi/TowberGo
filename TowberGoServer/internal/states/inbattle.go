package states

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
	"fmt"
)

type InBattle struct {
	client      internal.ClientInterface
	Player      *objects.Player
	BattleRoom  *objects.BattleRoom
	Num         int
	currentPet  *objects.BattlePet
	equippedPet [5]*objects.BattlePet
	SavedState  internal.ClientStateHandler
}

func (i *InBattle) Name() string {
	return "InBattle"
}

func (i *InBattle) SetClient(client internal.ClientInterface) {
	i.client = client
}

func (i *InBattle) OnEnter() {
	msg := packets.Packet_SyncState{SyncState: &packets.SyncState{State: 3}}
	i.client.SocketSend(&msg)
	i.Player.PetBagLock.RLock()
	defer i.Player.PetBagLock.RUnlock()
	for k, v := range i.Player.EquippedPets {
		i.equippedPet[k] = &objects.BattlePet{
			Pet:   v,
			Buffs: nil,
		}
	}
	i.currentPet = i.equippedPet[0]
}

func (i *InBattle) HandleMessage(senderID uint32, message packets.Msg) {
	battleMsg, ok := message.(*packets.Packet_BattlePacket)
	if !ok {
		return
	}
	i.ProcessMessage(battleMsg.BattlePacket.Msg)
}

func (i *InBattle) OnExit() {}

func (i *InBattle) ClearResources() {
	if i.Player.Area != nil {
		i.Player.Area.RemovePlayer(i.Player.UID)
	}
	if i.BattleRoom != nil {
		// 替换自动
		i.BattleRoom.ReplacePlayerAuto(i.Num)
	}
}

func (i *InBattle) ProcessMessage(message packets.BattleMsg) {
	switch battleMsg := message.(type) {
	case *packets.BattlePacket_Command:
		command := objects.Command{
			Msg:    battleMsg.Command,
			Number: i.Num,
		}
		i.BattleRoom.CommandChan <- &command
	case *packets.BattlePacket_RoundConfirm:
		i.BattleRoom.NextRoundChan <- i.Num
	case *packets.BattlePacket_ChangePet:
		i.BattleRoom.CommandChan <- &objects.Command{
			Msg: &packets.RoundCommandMessage{Command: &packets.RoundCommandMessage_ChangePet{
				ChangePet: &packets.ChangePet{PetPosition: battleMsg.ChangePet.PetPosition}}},
			Number: i.Num,
		}
	case *packets.BattlePacket_BattleEnd:
		fmt.Println(i.Player.UserName, "结束战斗")
		i.client.SocketSend(&packets.Packet_BattlePacket{BattlePacket: &packets.BattlePacket{Msg: battleMsg}})
		i.client.SetState(i.SavedState)
	case *packets.BattlePacket_StartNextRound, *packets.BattlePacket_DenyCommand, *packets.BattlePacket_AttackStats,
		*packets.BattlePacket_ChangePetRequest, *packets.BattlePacket_SyncBattleInformation, *packets.BattlePacket_RoundEnd:
		i.client.SocketSend(&packets.Packet_BattlePacket{BattlePacket: &packets.BattlePacket{Msg: battleMsg}})
	}
}

func (i *InBattle) CurrentPet() *objects.BattlePet {
	return i.currentPet
}

func (i *InBattle) SetCurrentPet(pet *objects.BattlePet) {
	i.currentPet = pet
}

func (i *InBattle) EquippedPets() [5]*objects.BattlePet {
	return i.equippedPet
}

func (i *InBattle) SetBattleRoom(room *objects.BattleRoom) {
	i.BattleRoom = room
}

func (i *InBattle) UserName() string {
	return i.Player.UserName
}

func (i *InBattle) GetPlayer() *objects.Player {
	return i.Player
}
