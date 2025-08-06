package objects

import (
	"TowberGoServer/internal/db"
	"TowberGoServer/pkg/packets"
	"context"
	"fmt"
	"strconv"
)

const deletePetItemLua = `
	local item_key = "player:" .. KEYS[1] .. ":petitem"
	local item_id = ARGV[1]
	local delete_count = tonumber(ARGV[2])
	
	local current_count = tonumber(redis.call("hget", item_key, item_id) or "0")
	if current_count < delete_count then
	return {err="数量不足"}
	end
	if current_count == delete_count then
	redis.call("hdel",item_key,item_id)
	return {pl="删除成功"}
	end
	redis.call("hincrby",item_key,item_id,-delete_count)
	return {ok="减少成功"}
`

const addPetItemLua = `
    local item_key = "player:" .. KEYS[1] .. ":petitem"
    local item_id = ARGV[1]
    local add_count = tonumber(ARGV[2])

    local current_count = tonumber(redis.call("hget", item_key, item_id) or "0")
    if current_count + add_count > 999 then
        return {err="数量超过上限"}
    end

    redis.call("hincrby", item_key, item_id, add_count)
    return {ok="添加成功"}
`

type PetItem interface {
	Use(pet Pet, count int) error
	Count() int
	ID() uint32
	Name() string
	Clone(count int) PetItem
}

type BasePetItem struct {
	Count int
	ID    uint32
}

func (b *BasePetItem) Convert() PetItem {
	return PetItemManager.NewItem(b.ID, b.Count)
}

var PetItemManager *PetItemManagerStruct

type PetItemManagerStruct struct {
	PetItemList map[uint32]PetItem
}

func (p *PetItemManagerStruct) NewItem(id uint32, count int) PetItem {
	newItem := p.PetItemList[id].Clone(count)
	return newItem
}

func (p *PetItemManagerStruct) AddItem(player *Player, id uint32, count int) error {
	ctx := context.Background()
	_, err := db.Rdb.Eval(ctx, addPetItemLua, []string{fmt.Sprint(player.UID)}, fmt.Sprint(id), fmt.Sprint(count)).Result()
	if err != nil {
		return err
	}

	// 向客户端发送添加宠物物品消息
	addMsg := packets.Packet_AddPetItem{AddPetItem: &packets.AddPetItemMessage{
		Id:    id,
		Count: int64(count),
	}}
	player.Client.SocketSend(&addMsg)
	return nil
}

func (p *PetItemManagerStruct) DeleteItem(player *Player, id uint32, count int) error {
	ctx := context.Background()
	_, err := db.Rdb.Eval(ctx, deletePetItemLua, []string{fmt.Sprint(player.UID)}, fmt.Sprint(id), fmt.Sprint(count)).Result()
	if err != nil {
		return err
	}
	deleteMsg := &packets.Packet_DeletePetItem{DeletePetItem: &packets.DeletePetItemMessage{
		Id:    id,
		Count: int64(count),
	}}
	player.Client.SocketSend(deleteMsg)
	return nil
}

func (p *PetItemManagerStruct) GetBags(player *Player) []BasePetItem {
	ctx := context.Background()
	result, err := db.Rdb.HGetAll(ctx, fmt.Sprintf("player:%d:petitem", player.UID)).Result()
	if err != nil {
		fmt.Println("get pet item bags error", err)
		return nil
	}
	res := make([]BasePetItem, 0, len(result))
	for stringID, stringCount := range result {
		id, _ := strconv.Atoi(stringID)
		count, _ := strconv.Atoi(stringCount)
		newItem := BasePetItem{
			ID:    uint32(id),
			Count: count,
		}
		res = append(res, newItem)
	}
	return res
}
