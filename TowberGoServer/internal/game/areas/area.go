package areas

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

var AreaMgr *AreaManager

type AreaManager struct {
	areas map[string]objects.Area
	hub   *internal.Hub
}

func NewAreaMgr(hub *internal.Hub, areas []objects.Area) *AreaManager {
	mgr := AreaManager{
		areas: make(map[string]objects.Area),
		hub:   hub,
	}
	for _, v := range areas {
		mgr.areas[v.Name()] = v
	}
	return &mgr
}

func (m *AreaManager) Get(name string) objects.Area {
	return m.areas[name]
}

func (m *AreaManager) Initialize() {
	for _, v := range m.areas {
		v.Initialize()
	}
}

type BaseArea struct {
	players   *containers.SharedIDMap[*objects.Player]
	expansion objects.Area
}

func (b *BaseArea) Initialize(e objects.Area) {
	b.players = containers.NewSharedIDMap[*objects.Player]()
	b.expansion = e
}

func (b *BaseArea) BroadcastArea(packet *packets.Packet, except bool) {
	b.players.ForEach(func(uid uint32, player *objects.Player) {
		if uid == packet.Uid && except || player == nil {
			return
		}
		player.Client.SocketSendAs(packet.Msg, packet.Uid)
	})
}

func (b *BaseArea) RemovePlayer(uid uint32) {
	p, _ := b.players.Get(uid)
	b.players.Remove(uid)
	p.Area = nil
	packet := packets.Packet{Uid: uid, Msg: &packets.Packet_PlayerLeave{PlayerLeave: &packets.PlayerLeaveAreaMessage{}}}
	b.BroadcastArea(&packet, true)
}

func (b *BaseArea) AddPlayer(player *objects.Player, id uint32) {
	msg := &packets.PlayerEnterAreaMessage{}
	otherInfo := &packets.Packet_PlayerEnter{PlayerEnter: msg}
	b.players.ForEach(func(uid uint32, p *objects.Player) {
		msg.X = p.Position.X
		msg.Y = p.Position.Y
		msg.Username = p.UserName
		player.Client.SocketSendAs(otherInfo, uid)
	})
	b.players.Set(player.UID, player)
	player.Area = b.expansion
	pos := b.expansion.GetEntrance(id)
	player.Position = pos
	packet := packets.Packet{Uid: player.UID, Msg: &packets.Packet_PlayerEnter{PlayerEnter: &packets.PlayerEnterAreaMessage{
		Username: player.UserName,
		X:        pos.X,
		Y:        pos.Y,
	}}}
	b.BroadcastArea(&packet, true)
	player.Client.SocketSend(packet.Msg)
}

func (b *BaseArea) ProcessMessage(senderID uint32, message packets.Msg) bool {
	processed := true
	switch message := message.(type) {
	case *packets.Packet_PlayerMovement:
		b.BroadcastArea(&packets.Packet{Uid: senderID, Msg: message}, true)
	case *packets.Packet_Chat:
		b.BroadcastArea(&packets.Packet{Uid: senderID, Msg: message}, false)
	default:
		processed = false
	}
	return processed
}
