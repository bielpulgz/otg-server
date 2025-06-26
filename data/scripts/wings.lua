-- Wings Attack Speed System
local STORAGE_ORIGINAL_SPEED = 50001

local wingsConfig = {
    [1655] = 100, -- 0.1 seconds
    [1656] = 150, -- 0.15 seconds  
    [1657] = 200, -- 0.2 seconds
    [1658] = 80,  -- 0.08 seconds
    [1659] = 120  -- 0.12 seconds
}

local function hasSpeedBonus(wingsId)
    return wingsConfig[wingsId] ~= nil
end

local function applyAttackSpeed(player, wingsId)
    if wingsId ~= 0 and hasSpeedBonus(wingsId) then
        local originalMs = player:getVocation():getAttackSpeed()
        local customSpeed = wingsConfig[wingsId]
        
        player:setStorageValue(STORAGE_ORIGINAL_SPEED, originalMs)
        player:setAttackSpeed(customSpeed)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Attack speed: " .. customSpeed .. "ms")
    else
        local originalSpeed = player:getStorageValue(STORAGE_ORIGINAL_SPEED)
        
        if originalSpeed ~= -1 then
            player:setStorageValue(STORAGE_ORIGINAL_SPEED, -1)
        end
        
        player:setAttackSpeed(0)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Attack speed restored to default")
    end
end

local ec = EventCallback
ec.onChangeOutfit = function(player, outfit)
    addEvent(function()
        if player:isPlayer() then
            applyAttackSpeed(player, outfit.lookWings or 0)
        end
    end, 0, player:getId())
    return true
end
ec:register()

local loginEvent = CreatureEvent("WingsLogin")
function loginEvent.onLogin(player)
    addEvent(function()
        if player:isPlayer() then
            local currentWings = player:getOutfit().lookWings or 0
            applyAttackSpeed(player, currentWings)
        end
    end, 0, player:getId())
    return true
end
loginEvent:register()