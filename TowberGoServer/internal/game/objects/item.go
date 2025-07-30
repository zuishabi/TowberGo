package objects

type Item interface {
	Use(player *Player)
	Count() int
	ID() uint64
	UseImmediately() bool
}
