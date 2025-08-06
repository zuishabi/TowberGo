package objects

type Manager struct {
}

type BattlePet struct {
	Pet
	States []State
}

type AttackInfo struct {
	From           *BattlePet
	PhysicalDamage int
	MagicDamage    int
	StateDamage    StateDamage
}

type StateDamage struct {
	ID    int
	level int
}

type State interface {
	ID() int
	Update(level int)
	SetPet(pet *BattlePet)
}
