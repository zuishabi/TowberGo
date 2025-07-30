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
	items := make([]*packets.ItemMessage, len(mail.Items))
	for i := range mail.Items {
		items[i] = &packets.ItemMessage{}
		items[i].Id = mail.Items[i].ID
		items[i].Count = mail.Items[i].Count
	}
	msg := &packets.Packet_Mail{Mail: &packets.MailMessage{
		Id:       mail.ID,
		Titles:   mail.Title,
		Contents: mail.Content,
		Sender:   mail.Sender,
		Items:    items,
	}}
	return msg
}
