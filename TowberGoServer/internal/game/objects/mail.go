package objects

import (
	"TowberGoServer/internal/db"
	"context"
	"encoding/json"
	"fmt"
	"strconv"
)

var MailManager *MailManagerStruct

type MailManagerStruct struct{}

type MailItem struct {
	ID    uint32
	Count uint32
	Type  uint32 // 记录物品类型，1是宠物物品，2是普通物品
}

type Mail struct {
	ID      uint32
	Title   string
	Content string
	Sender  string
	Items   []MailItem
}

func (m *MailManagerStruct) SendMail(uid uint32, mail *Mail) {
	ctx := context.Background()

	// 1. 转换 Mail 为 JSON
	mailJson, err := json.Marshal(mail)
	if err != nil {
		fmt.Println("send mail error:", err)
		return
	}

	// 2. Lua 脚本：自增 mail_id 并存储邮件
	luaScript := `
        local mail_id_key = "player:" .. KEYS[1] .. ":mail_id"
        local mail_hash_key = "player:" .. KEYS[1] .. ":mail"
        local new_id = redis.call("incr", mail_id_key)
        redis.call("hset", mail_hash_key, new_id, ARGV[1])
        return new_id
    `
	// 3. 执行 Lua 脚本
	result, err := db.Rdb.Eval(ctx, luaScript, []string{fmt.Sprint(uid)}, string(mailJson)).Result()
	if err != nil {
		// 处理错误
		fmt.Println("send mail error:", err)
		return
	}
	fmt.Println("send mail success:", result)
}

// SendMailToAll 向服务器中所有用户发送邮件
func (m *MailManagerStruct) SendMailToAll() {

}

// DeleteMail 删除指定邮件
func (m *MailManagerStruct) DeleteMail(uid uint32, mailID uint32) {
	ctx := context.Background()
	if err := db.Rdb.HDel(ctx, fmt.Sprintf("player:%d:mail", uid), fmt.Sprintf("%d", mailID)).Err(); err != nil {
		fmt.Println("delete mail error", err)
	}
}

func (m *MailManagerStruct) CollectMail(player *Player, mailID uint32) error {
	ctx := context.Background()
	result, err := db.Rdb.HGet(ctx, fmt.Sprintf("player:%d:mail", player.UID), fmt.Sprint(mailID)).Result()
	if err != nil {
		return err
	}
	mail := &Mail{}
	_ = json.Unmarshal([]byte(result), mail)
	for i := range mail.Items {
		if mail.Items[i].Type == 1 {
			if err := PetItemManager.AddItem(player, mail.Items[i].ID, int(mail.Items[i].Count)); err != nil {
				mail.Items = mail.Items[i:]
				// 更新 Redis 中的邮件内容
				mailJson, _ := json.Marshal(mail)
				db.Rdb.HSet(ctx, fmt.Sprintf("player:%d:mail", player.UID), fmt.Sprint(mailID), mailJson)
				return err
			}
		} else {
			if err := ItemManager.AddItem(player, mail.Items[i].ID, int(mail.Items[i].Count)); err != nil {
				mail.Items = mail.Items[i:]
				// 更新 Redis 中的邮件内容
				mailJson, _ := json.Marshal(mail)
				db.Rdb.HSet(ctx, fmt.Sprintf("player:%d:mail", player.UID), fmt.Sprint(mailID), mailJson)
				return err
			}
		}

	}
	m.DeleteMail(player.UID, mailID)
	return nil
}

func (m *MailManagerStruct) GetMails(uid uint32) []Mail {
	ctx := context.Background()

	result, err := db.Rdb.HGetAll(ctx, fmt.Sprintf("player:%d:mail", uid)).Result()
	if err != nil {
		fmt.Println("get mails error", err)
		return nil
	}
	fmt.Println(result)
	res := make([]Mail, 0, len(result))
	for i := range result {
		mail := Mail{}
		err = json.Unmarshal([]byte(result[i]), &mail)
		if err != nil {
			fmt.Println("unmarshal mail error", err)
			continue
		}
		id, err := strconv.Atoi(i)
		if err != nil {
			fmt.Println("strconv mail id error", err)
			return nil
		}
		mail.ID = uint32(id)
		res = append(res, mail)
	}
	return res
}
