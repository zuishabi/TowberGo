package objects

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
)

type Player struct {
	UserName string
	UID      uint32
	Client   internal.ClientInterface
	Position containers.Vector2
	Area     Area
}
