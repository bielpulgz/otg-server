-- Global storage table initialization
if not globalStorageTable then
    globalStorageTable = {}
end

-- Database-backed global storage retrieval
function getGlobalStorageValueDB(key)
    if type(key) ~= "number" then
        print("[Warning] getGlobalStorageValueDB: Invalid key type, expected number, got " .. type(key))
        return -1
    end

    local query = string.format("SELECT `value` FROM `global_storage` WHERE `key` = %d", key)
    local resultId = db.storeQuery(query)
    if resultId then
        local val = result.getString(resultId, "value")
        result.free(resultId)
        return val or -1
    end
    return -1
end

-- Database-backed global storage update
function setGlobalStorageValueDB(key, value)
    if type(key) ~= "number" then
        print("[Warning] setGlobalStorageValueDB: Invalid key type, expected number, got " .. type(key))
        return false
    end
    if value == nil then
        print("[Warning] setGlobalStorageValueDB: Value cannot be nil for key " .. key)
        return false
    end

    local query = string.format(
        "INSERT INTO `global_storage` (`key`, `value`) VALUES (%d, %s) ON DUPLICATE KEY UPDATE `value` = %s",
        key, db.escapeString(tostring(value)), db.escapeString(tostring(value))
    )
    local success, err = db.query(query)
    if not success then
        print("[Error] setGlobalStorageValueDB: Failed to execute query: " .. (err or "unknown error"))
        return false
    end
    return true
end

-- Broadcast message to all players
function Game.broadcastMessage(message, messageType)
    if type(message) ~= "string" or message == "" then
        print("[Warning] Game.broadcastMessage: Invalid or empty message")
        return false
    end

    messageType = messageType or MESSAGE_STATUS_WARNING
    if not isValidMessageType(messageType) then
        print("[Warning] Game.broadcastMessage: Invalid messageType, defaulting to MESSAGE_STATUS_WARNING")
        messageType = MESSAGE_STATUS_WARNING
    end

    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        if player and player.sendTextMessage then
            player:sendTextMessage(messageType, message)
        end
    end
    return true
end

-- Convert IP address from integer to string format
function Game.convertIpToString(ip)
    if type(ip) ~= "number" or ip < 0 then
        print("[Warning] Game.convertIpToString: Invalid IP value, expected non-negative number, got " .. tostring(ip))
        return "0.0.0.0"
    end

    local band = bit.band
    local rshift = bit.rshift
    return string.format("%d.%d.%d.%d",
        band(ip, 0xFF),
        band(rshift(ip, 8), 0xFF),
        band(rshift(ip, 16), 0xFF),
        rshift(ip, 24)
    )
end

-- Find house owned by a player GUID
function Game.getHouseByPlayerGUID(playerGUID)
    if type(playerGUID) ~= "number" or playerGUID <= 0 then
        print("[Warning] Game.getHouseByPlayerGUID: Invalid playerGUID, expected positive number, got " .. tostring(playerGUID))
        return nil
    end

    local houses = Game.getHouses()
    for _, house in ipairs(houses) do
        if house and house.getOwnerGuid and house:getOwnerGuid() == playerGUID then
            return house
        end
    end
    return nil
end

-- Get players by account number
function Game.getPlayersByAccountNumber(accountNumber)
    if type(accountNumber) ~= "number" or accountNumber <= 0 then
        print("[Warning] Game.getPlayersByAccountNumber: Invalid accountNumber, expected positive number, got " .. tostring(accountNumber))
        return {}
    end

    local result = {}
    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        if player and player.getAccountId and player:getAccountId() == accountNumber then
            table.insert(result, player)
        end
    end
    return result
end

-- Get players by IP address with optional mask
function Game.getPlayersByIPAddress(ip, mask)
    if type(ip) ~= "number" or ip < 0 then
        print("[Warning] Game.getPlayersByIPAddress: Invalid IP, expected non-negative number, got " .. tostring(ip))
        return {}
    end
    mask = mask or 0xFFFFFFFF
    if type(mask) ~= "number" then
        print("[Warning] Game.getPlayersByIPAddress: Invalid mask, defaulting to 0xFFFFFFFF")
        mask = 0xFFFFFFFF
    end

    local masked = bit.band(ip, mask)
    local result = {}
    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        if player and player.getIp and bit.band(player:getIp(), mask) == masked then
            table.insert(result, player)
        end
    end
    return result
end

-- Map weapon type to skill type
function Game.getSkillType(weaponType)
    local skillMap = {
        [WEAPON_CLUB] = SKILL_CLUB,
        [WEAPON_SWORD] = SKILL_SWORD,
        [WEAPON_AXE] = SKILL_AXE,
        [WEAPON_DISTANCE] = SKILL_DISTANCE,
        [WEAPON_SHIELD] = SKILL_SHIELD
    }
    return skillMap[weaponType] or SKILL_FIST
end

-- In-memory global storage access
function Game.getStorageValue(key)
    if key == nil then
        print("[Warning] Game.getStorageValue: Key cannot be nil")
        return nil
    end
    return globalStorageTable[key]
end

function Game.setStorageValue(key, value)
    if key == nil then
        print("[Warning] Game.setStorageValue: Key cannot be nil")
        return false
    end
    globalStorageTable[key] = value
    return true
end

-- Get last server save timestamp
function Game.getLastServerSave()
    return Game.getStorageValue(GlobalStorageKeys.LastServerSave) or 0
end

-- Get reverse direction
function Game.getReverseDirection(direction)
    local reverseMap = {
        [DIRECTION_WEST] = DIRECTION_EAST,
        [DIRECTION_EAST] = DIRECTION_WEST,
        [DIRECTION_NORTH] = DIRECTION_SOUTH,
        [DIRECTION_SOUTH] = DIRECTION_NORTH,
        [DIRECTION_NORTHWEST] = DIRECTION_SOUTHEAST,
        [DIRECTION_NORTHEAST] = DIRECTION_SOUTHWEST,
        [DIRECTION_SOUTHWEST] = DIRECTION_NORTHEAST,
        [DIRECTION_SOUTHEAST] = DIRECTION_NORTHWEST
    }
    return reverseMap[direction] or DIRECTION_NORTH
end

-- Quest system management
do
    local quests = {}
    local missions = {}
    local trackedQuests = {}

    function Game.getQuests() return quests end
    function Game.getMissions() return missions end
    function Game.getTrackedQuests() return trackedQuests end
    function Game.getQuestById(id) return quests[id] end
    function Game.getMissionById(id) return missions[id] end

    function Game.clearQuests()
        quests = {}
        missions = {}
        for playerId, _ in pairs(trackedQuests) do
            local player = Player(playerId)
            if player and player.sendQuestTracker then
                player:sendQuestTracker({})
            end
        end
        trackedQuests = {}
        return true
    end

    function Game.createQuest(name, quest)
        if not isScriptsInterface() then
            print("[Warning] Game.createQuest: Called outside scripts interface")
            return nil
        end
        if type(name) ~= "string" or name == "" then
            print("[Warning] Game.createQuest: Invalid or empty quest name")
            return nil
        end

        local newQuest
        if type(quest) == "table" then
            newQuest = setmetatable(quest, Quest)
            newQuest.missions = quest.missions or {}
        else
            newQuest = setmetatable({}, Quest)
            newQuest.missions = {}
        end

        newQuest.id = -1
        newQuest.name = name
        newQuest.storageId = 0
        newQuest.storageValue = 0
        return newQuest
    end

    function Game.isQuestStorage(key, value, oldValue)
        if type(key) ~= "number" or type(value) ~= "number" then
            return false
        end

        for _, quest in pairs(quests) do
            if quest.storageId == key and quest.storageValue == value then
                return true
            end
        end

        for _, mission in pairs(missions) do
            if mission.storageId == key and value >= mission.startValue and value <= mission.endValue then
                return not mission.description or oldValue < mission.startValue or oldValue > mission.endValue
            end
        end
        return false
    end
end

-- Helper function to validate message types
function isValidMessageType(messageType)
    local validTypes = {
        MESSAGE_STATUS_WARNING,
        MESSAGE_STATUS_DEFAULT,
        MESSAGE_STATUS_CONSOLE,
        MESSAGE_EVENT_ADVANCE,
        MESSAGE_EVENT_DEFAULT,
        -- Add other valid message types as needed
    }
    for _, validType in ipairs(validTypes) do
        if messageType == validType then
            return true
        end
    end
    return false
end