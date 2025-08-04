package objects

import (
	"TowberGoServer/internal/db"
	"TowberGoServer/pkg/packets"
	"context"
	"fmt"
	"strconv"
)

type Item interface {
	Use(player *Player, count int) error
	Count() int
	ID() uint32
	UseImmediately() bool
	Name() string
	Clone(count int) Item
}

var ItemManager *ItemManagerStruct

const AddLua = `
local item_key = "player:" .. KEYS[1] .. ":item"
local item_id = ARGV[1]
local add_count = tonumber(ARGV[2])

local current_count = tonumber(redis.call("hget", item_key, item_id) or "0")
if current_count + add_count > 999 then
    return {err="数量超过上限"}
end

redis.call("hincrby", item_key, item_id, add_count)
return {ok="添加成功"}
`

const DeleteLua = `
local item_key = "player:" .. KEYS[1] .. ":item"
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

type BaseItem struct {
	ID    uint32
	Count int
}

func (b *BaseItem) Convert() Item {
	return ItemManager.NewItem(b.ID, b.Count)
}

type ItemManagerStruct struct {
	ItemMap map[uint32]Item
}

func (i *ItemManagerStruct) NewItem(id uint32, count int) Item {
	newItem := i.ItemMap[id].Clone(count)
	return newItem
}

func (i *ItemManagerStruct) AddItem(player *Player, id uint32, count int) error {
	if i.ItemMap[id].UseImmediately() {
		items := i.NewItem(id, count)
		if err := items.Use(player, count); err != nil {
			return err
		}
		return nil
	}
	ctx := context.Background()
	_, err := db.Rdb.Eval(ctx, AddLua, []string{fmt.Sprint(player.UID)}, fmt.Sprint(id), fmt.Sprint(count)).Result()
	if err != nil {
		return err
	}

	// 向客户端发送添加物品消息
	addMsg := packets.Packet_AddBagItem{AddBagItem: &packets.AddBagItemMessage{
		Id:    id,
		Count: int64(count),
	}}
	player.Client.SocketSend(&addMsg)
	return nil
}

func (i *ItemManagerStruct) DeleteItem(player *Player, id uint32, count int) error {
	ctx := context.Background()
	_, err := db.Rdb.Eval(ctx, DeleteLua, []string{fmt.Sprint(player.UID)}, fmt.Sprint(id), fmt.Sprint(count)).Result()
	if err != nil {
		return err
	}
	deleteMsg := &packets.Packet_DeleteBagItem{DeleteBagItem: &packets.DeleteBagItemMessage{
		Id:    id,
		Count: int64(count),
	}}
	player.Client.SocketSend(deleteMsg)
	return nil
}

func (i *ItemManagerStruct) GetBags(player *Player) []BaseItem {
	ctx := context.Background()
	result, err := db.Rdb.HGetAll(ctx, fmt.Sprintf("player:%d:item", player.UID)).Result()
	if err != nil {
		fmt.Println("get bags error", err)
		return nil
	}
	res := make([]BaseItem, 0, len(result))
	for stringID, stringCount := range result {
		id, _ := strconv.Atoi(stringID)
		count, _ := strconv.Atoi(stringCount)
		newItem := BaseItem{
			ID:    uint32(id),
			Count: count,
		}
		res = append(res, newItem)
	}
	return res
}
