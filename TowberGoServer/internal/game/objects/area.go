package objects

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
	"TowberGoServer/pkg/packets"
)

type Area interface {
	GetEntrance(id uint32) containers.Vector2
	Name() string
	AddPlayer(player *Player, id uint32)
	RemovePlayer(uid uint32)
	BroadcastArea(packet *packets.Packet, except bool)
	// ProcessMessage 将消息传递给area处理
	ProcessMessage(sender *Player, packet packets.Msg)
	Initialize()
	CheckCanEnter(player *Player) (bool, string)
}

var AreaMgr *AreaManager

type AreaManager struct {
	areas map[string]Area
	hub   *internal.Hub
}

func NewAreaMgr(hub *internal.Hub, areas []Area) *AreaManager {
	mgr := AreaManager{
		areas: make(map[string]Area),
		hub:   hub,
	}
	for _, v := range areas {
		mgr.areas[v.Name()] = v
	}
	return &mgr
}

func (m *AreaManager) Get(name string) Area {
	return m.areas[name]
}

func (m *AreaManager) Initialize() {
	for _, v := range m.areas {
		v.Initialize()
	}
}

type BaseArea struct {
	Players   *containers.SharedIDMap[*Player]
	Expansion Area
}

func (b *BaseArea) Initialize(e Area) {
	b.Players = containers.NewSharedIDMap[*Player]()
	b.Expansion = e
}

func (b *BaseArea) BroadcastArea(packet *packets.Packet, except bool) {
	b.Players.ForEach(func(uid uint32, player *Player) {
		if uid == packet.Uid && except || player == nil {
			return
		}
		player.Client.SocketSendAs(packet.Msg, packet.Uid)
	})
}

func (b *BaseArea) RemovePlayer(uid uint32) {
	p, _ := b.Players.Get(uid)
	b.Players.Remove(uid)
	p.Area = nil
	packet := packets.Packet{Uid: uid, Msg: &packets.Packet_PlayerLeave{PlayerLeave: &packets.PlayerLeaveAreaMessage{}}}
	b.BroadcastArea(&packet, true)
}

func (b *BaseArea) AddPlayer(player *Player, id uint32) {
	msg := &packets.PlayerEnterAreaMessage{}
	otherInfo := &packets.Packet_PlayerEnter{PlayerEnter: msg}
	b.Players.ForEach(func(uid uint32, p *Player) {
		if player == nil {
			return
		}
		msg.X = p.Position.X
		msg.Y = p.Position.Y
		msg.Username = p.UserName
		player.Client.SocketSendAs(otherInfo, uid)
	})
	b.Players.Set(player.UID, player)
	player.Area = b.Expansion
	pos := b.Expansion.GetEntrance(id)
	player.Position = pos
	packet := packets.Packet{Uid: player.UID, Msg: &packets.Packet_PlayerEnter{PlayerEnter: &packets.PlayerEnterAreaMessage{
		Username: player.UserName,
		X:        pos.X,
		Y:        pos.Y,
	}}}
	b.BroadcastArea(&packet, true)
	player.Client.SocketSend(packet.Msg)
}

func (b *BaseArea) ProcessMessage(sender *Player, message packets.Msg) bool {
	processed := true
	switch message := message.(type) {
	case *packets.Packet_PlayerMovement:
		b.BroadcastArea(&packets.Packet{Uid: sender.UID, Msg: message}, true)
	case *packets.Packet_Chat:
		b.BroadcastArea(&packets.Packet{Uid: sender.UID, Msg: message}, false)
	default:
		processed = false
	}
	return processed
}
