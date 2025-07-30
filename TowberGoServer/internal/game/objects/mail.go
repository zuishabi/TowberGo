package objects

import (
	"TowberGoServer/internal/db"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
)

var MailManager *MailManagerStruct

type MailManagerStruct struct{}

type MailItem struct {
	ID    uint32
	Count uint32
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
	fmt.Println(mailID)
	if err := db.Rdb.HDel(ctx, fmt.Sprintf("player:%d:mail", uid), fmt.Sprintf("%d", mailID)).Err(); err != nil {
		fmt.Println("delete mail error", err)
	}
}

func (m *MailManagerStruct) CollectMail() error {
	return errors.New("the collect function has not complete")
}

func (m *MailManagerStruct) GetMails(uid uint32) []Mail {
	fmt.Println("get mails")
	ctx := context.Background()
	fmt.Println(uid)

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
