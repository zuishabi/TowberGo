package packets

type Msg isPacket_Msg

func NewPlayerEnterAreaResponse(success bool, reason string, areaName string) Msg {
	msg := &Packet_PlayerEnterAreaResponse{PlayerEnterAreaResponse: &PlayerEnterAreaResponseMessage{
		AreaName: areaName,
		Success:  success,
		Reason:   reason,
	}}
	return msg
}
