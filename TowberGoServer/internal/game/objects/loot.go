package objects

import "math/rand/v2"

type LootTable interface {
	getTableSize() int
	getTable() []*Loot
	getCount() int
}

type Loot struct {
	ID     uint32
	Type   uint32 // 1：宠物道具，2：道具
	Weight float32
}

var LootManager *LootManagerStruct

type LootManagerStruct struct{}

func (l *LootManagerStruct) GetLoot(player *Player, lootTable LootTable, value float32, certainCount ...int) error {
	// 随机生成1-5个物品
	count := rand.IntN(lootTable.getCount()) + 1
	if len(certainCount) > 0 {
		count = certainCount[0]
	}
	itemList := make(map[uint32]int)
	petItemList := make(map[uint32]int)
	for n := 0; n < count; n++ {
		// 调整权重
		adjusted := make([]float32, lootTable.getTableSize())
		var total float32
		for idx, loot := range lootTable.getTable() {
			adjusted[idx] = loot.Weight * (1 + value*float32(idx))
			total += adjusted[idx]
		}
		// 随机抽取
		r := rand.Float32() * total
		var sum float32

		for idx, w := range adjusted {
			sum += w
			if r <= sum {
				if lootTable.getTable()[idx].Type == 1 {
					petItemList[lootTable.getTable()[idx].ID] += 1
					break
				} else {
					// 给玩家添加 lootTable[idx]
					itemList[lootTable.getTable()[idx].ID] += 1
					break
				}

			}
		}
	}
	var err error
	for i, v := range itemList {
		if e := ItemManager.AddItem(player, i, v); e != nil {
			err = e
		}
	}
	for i, v := range petItemList {
		if e := ItemManager.AddItem(player, i, v); e != nil {
			err = e
		}
	}
	return err
}
