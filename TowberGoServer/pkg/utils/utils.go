package utils

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

func NewPlayerEnterAreaResponse(success bool, reason string, areaName string) packets.Msg {
	msg := &packets.Packet_PlayerEnterAreaResponse{PlayerEnterAreaResponse: &packets.PlayerEnterAreaResponseMessage{
		AreaName: areaName,
		Success:  success,
		Reason:   reason,
	}}
	return msg
}

func NewMailMessages(mail *objects.Mail) packets.Msg {
	items := make([]*packets.ItemMessage, 0)
	petItems := make([]*packets.PetItemMessage, 0)
	for i := range mail.Items {
		if mail.Items[i].Type == 1 {
			item := &packets.PetItemMessage{
				Id:    mail.Items[i].ID,
				Count: int64(mail.Items[i].Count),
			}
			petItems = append(petItems, item)
		} else {
			item := &packets.ItemMessage{
				Id:    mail.Items[i].ID,
				Count: int64(mail.Items[i].Count),
			}
			items = append(items, item)
		}
	}
	msg := &packets.Packet_Mail{Mail: &packets.MailMessage{
		Id:       mail.ID,
		Titles:   mail.Title,
		Contents: mail.Content,
		Sender:   mail.Sender,
		Items:    items,
		PetItems: petItems,
	}}
	return msg
}

func NewBagMessage(items []objects.BaseItem) packets.Msg {
	ids := make([]uint32, len(items))
	counts := make([]int64, len(items))
	for i, v := range items {
		ids[i] = v.ID
		counts[i] = int64(v.Count)
	}
	return &packets.Packet_Bag{Bag: &packets.BagMessage{
		Id:    ids,
		Count: counts,
	}}
}

func NewPetItemBagMessage(items []objects.BasePetItem) packets.Msg {
	ids := make([]uint32, len(items))
	counts := make([]int64, len(items))
	for i, v := range items {
		ids[i] = v.ID
		counts[i] = int64(v.Count)
	}
	return &packets.Packet_PetItemBagResponse{PetItemBagResponse: &packets.PetItemBagResponseMessage{
		Id:    ids,
		Count: counts,
	}}
}

func NewPetMessage(pet objects.Pet) *packets.PetMessage {
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

func NewAttackStatsPacket(msg *packets.AttackStatsMessage) packets.BattleMsg {
	return &packets.BattlePacket_AttackStats{AttackStats: msg}
}
