function add_pet_item()
    local item_key = "player:" .. KEYS[1] .. ":petitem"
    local item_id = ARGV[1]
    local add_count = tonumber(ARGV[2])

    local current_count = tonumber(redis.call("hget", item_key, item_id) or "0")
    if current_count + add_count > 999 then
        return {err="数量超过上限"}
    end

    redis.call("hincrby", item_key, item_id, add_count)
    return {ok="添加成功"}
end

function delete_pet_item()
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
end