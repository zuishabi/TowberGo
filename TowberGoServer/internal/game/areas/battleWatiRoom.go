package areas

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/states"
	"TowberGoServer/pkg/packets"
	"fmt"
	"sync"
	"time"
)

type BattleWaitRooms struct {
	currentID uint32
	waitMap   map[uint32]*BattleUnit
	lock      sync.Mutex
}

func (b *BattleWaitRooms) Start() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for {
		<-ticker.C
		b.lock.Lock()
		now := time.Now()
		for id, unit := range b.waitMap {
			if now.Sub(unit.startTime) > 10*time.Second {
				delete(b.waitMap, id)
			}
		}
		b.lock.Unlock()
	}
}

func (b *BattleWaitRooms) CreateRoom(master *objects.Player, target *objects.Player) {
	b.lock.Lock()
	defer b.lock.Unlock()
	b.currentID += 1
	b.waitMap[b.currentID] = &BattleUnit{Players: [2]*objects.Player{master, target}, startTime: time.Now()}

	// 向目标发送请求
	msg := &packets.Packet_BattleInviting{BattleInviting: &packets.BattleInvitingMessage{
		RoomID:   b.currentID,
		UserName: master.UserName,
	}}
	target.Client.SocketSend(msg)
}

func (b *BattleWaitRooms) AcceptRoom(roomID uint32, playerID uint32) {
	fmt.Println("接收")
	b.lock.Lock()
	defer b.lock.Unlock()
	unit := b.waitMap[roomID]
	fmt.Println(1)
	if unit != nil && unit.Players[1].UID == playerID {
		fmt.Println(2, unit.Players)
		// 发送开始战斗，将两人转换为战斗状态

		fmt.Println("a")
		msg := &packets.StartBattleMessage{Number: 0}
		unit.Players[0].Client.SocketSend(&packets.Packet_StartBattle{StartBattle: msg})
		state1 := &states.InBattle{Player: unit.Players[0], Num: 0}
		unit.Players[0].Client.SetState(state1)

		fmt.Println("b")
		msg.Number = 1
		unit.Players[1].Client.SocketSend(&packets.Packet_StartBattle{StartBattle: msg})
		state2 := &states.InBattle{Player: unit.Players[1], Num: 1}
		unit.Players[1].Client.SetState(state2)

		_ = objects.BattleManager.CreateRoom([2]objects.BattlePlayer{state1, state2})
		// 删除邀请房间
		delete(b.waitMap, roomID)
	}
}

func (b *BattleWaitRooms) RejectRoom(roomID uint32) {
	b.lock.Lock()
	defer b.lock.Unlock()
	delete(b.waitMap, roomID)
}

type BattleUnit struct {
	Players   [2]*objects.Player
	startTime time.Time
}
