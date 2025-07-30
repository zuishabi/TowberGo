local mail_id_key = "player:" .. KEYS[1] .. ":mail_id"
local mail_hash_key = "player:" .. KEYS[1] .. ":mail"
local new_id = redis.call("incr", mail_id_key)
redis.call("hset", mail_hash_key, new_id, ARGV[1])
return new_id