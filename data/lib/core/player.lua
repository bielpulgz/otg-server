-- Player Utility Functions for OpenTibia Server

-- Global condition for food regeneration
local foodCondition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)

-- Helper function to validate player object
local function isValidPlayer(player)
    return player and player:isPlayer() and player.getId and player:getId() > 0
end

-- Helper function to validate NetworkMessage
local function sendNetworkMessage(player, msg)
    if not msg or not isValidPlayer(player) then
        print("[Warning] sendNetworkMessage: Invalid player or message")
        return false
    end
    msg:sendToPlayer(player)
    msg:delete()
    return true
end

-- Section: Condition Management

-- Feed the player, extending or applying a regeneration condition
-- @param food: Duration in seconds to extend regeneration
-- @return: True if successful, nil/false on failure
function Player.feed(self, food)
    if not isValidPlayer(self) then
        print("[Warning] Player.feed: Invalid player object")
        return false
    end
    if type(food) ~= "number" or food <= 0 then
        print("[Warning] Player.feed: Invalid food duration, expected positive number, got " .. tostring(food))
        return false
    end

    local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
    if condition then
        condition:setTicks(condition:getTicks() + (food * 1000))
        return true
    end

    local vocation = self:getVocation()
    if not vocation then
        print("[Warning] Player.feed: Player has no vocation")
        return nil
    end

    foodCondition:setTicks(food * 1000)
    foodCondition:setParameter(CONDITION_PARAM_HEALTHGAIN, vocation:getHealthGainAmount() or 0)
    foodCondition:setParameter(CONDITION_PARAM_HEALTHTICKS, (vocation:getHealthGainTicks() or 0) * 1000)
    foodCondition:setParameter(CONDITION_PARAM_MANAGAIN, vocation:getManaGainAmount() or 0)
    foodCondition:setParameter(CONDITION_PARAM_MANATICKS, (vocation:getManaGainTicks() or 0) * 1000)

    self:addCondition(foodCondition)
    return true
end

-- Section: Position and Movement

-- Get the closest free position for the player
-- @param position: The target position (table with x, y, z)
-- @param extended: Optional boolean to check extended area
-- @return: The closest free position or the input position for privileged players
function Player.getClosestFreePosition(self, position, extended)
    if not isValidPlayer(self) then
        print("[Warning] Player.getClosestFreePosition: Invalid player object")
        return nil
    end
    if not position or type(position) ~= "table" or not position.x or not position.y or not position.z then
        print("[Warning] Player.getClosestFreePosition: Invalid position")
        return nil
    end

    if self:getAccountType() >= ACCOUNT_TYPE_GOD then
        return position
    end

    return Creature.getClosestFreePosition(self, position, extended or false)
end

-- Check if the player allows movement
-- @return: True if movement is allowed, false otherwise
function Player.hasAllowMovement(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.hasAllowMovement: Invalid player object")
        return false
    end
    return self:getStorageValue(STORAGE.blockMovementStorage) ~= 1
end

-- Section: Inventory and Items

-- Get the number of items in a depot chest
-- @param depotId: The ID of the depot chest
-- @return: Number of items or 0 on failure
function Player.getDepotItems(self, depotId)
    if not isValidPlayer(self) then
        print("[Warning] Player.getDepotItems: Invalid player object")
        return 0
    end
    if type(depotId) ~= "number" or depotId < 0 then
        print("[Warning] Player.getDepotItems: Invalid depotId, expected non-negative number, got " .. tostring(depotId))
        return 0
    end

    local depotChest = self:getDepotChest(depotId, true)
    return depotChest and depotChest:getItemHoldingCount() or 0
end

-- Check if the player has a Rookgaard shield
-- @return: True if any specified shield is present, false otherwise
function Player.hasRookgaardShield(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.hasRookgaardShield: Invalid player object")
        return false
    end

    local shields = {2512, 2526, 2511, 2510, 2530} -- Wooden, Studded, Brass, Plate, Copper
    for _, shieldId in ipairs(shields) do
        if self:getItemCount(shieldId) > 0 then
            return true
        end
    end
    return false
end

-- Section: Blessings and Loss

-- Get the number of blessings the player has
-- @return: Number of blessings (0-5)
function Player.getBlessings(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.getBlessings: Invalid player object")
        return 0
    end

    local blessings = 0
    for i = 1, 5 do
        if self:hasBlessing(i) then
            blessings = blessings + 1
        end
    end
    return blessings
end

-- Get the experience loss percentage based on blessings
-- @return: Loss percentage (0-100)
function Player.getLossPercent(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.getLossPercent: Invalid player object")
        return 100
    end

    local lossPercent = {[0] = 100, [1] = 70, [2] = 45, [3] = 25, [4] = 10, [5] = 0}
    return lossPercent[self:getBlessings()] or 100
end

-- Section: Vocation and Status

-- Check if the player is a druid
-- @return: True if druid, false otherwise
function Player.isDruid(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isDruid: Invalid player object")
        return false
    end
    local vocation = self:getVocation()
    return vocation and isInArray({2, 6}, vocation:getId())
end

-- Check if the player is a knight
-- @return: True if knight, false otherwise
function Player.isKnight(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isKnight: Invalid player object")
        return false
    end
    local vocation = self:getVocation()
    return vocation and isInArray({4, 8}, vocation:getId())
end

-- Check if the player is a paladin
-- @return: True if paladin, false otherwise
function Player.isPaladin(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isPaladin: Invalid player object")
        return false
    end
    local vocation = self:getVocation()
    return vocation and isInArray({3, 7}, vocation:getId())
end

-- Check if the player is a mage (sorcerer or druid)
-- @return: True if mage, false otherwise
function Player.isMage(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isMage: Invalid player object")
        return false
    end
    local vocation = self:getVocation()
    return vocation and isInArray({1, 2, 5, 6}, vocation:getId())
end

-- Check if the player is a sorcerer
-- @return: True if sorcerer, false otherwise
function Player.isSorcerer(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isSorcerer: Invalid player object")
        return false
    end
    local vocation = self:getVocation()
    return vocation and isInArray({1, 5}, vocation:getId())
end

-- Check if the player is promoted
-- @return: True if promoted, false otherwise
function Player.isPromoted(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isPromoted: Invalid player object")
        return false
    end

    local vocation = self:getVocation()
    if not vocation then
        return false
    end

    local promotedVocation = vocation:getPromotion()
    return promotedVocation and vocation:getId() ~= promotedVocation:getId()
end

-- Section: Account and Privileges

-- Check if the player has a specific group flag
-- @param flag: The group flag to check
-- @return: True if the flag is set, false otherwise
function Player.hasFlag(self, flag)
    if not isValidPlayer(self) then
        print("[Warning] Player.hasFlag: Invalid player object")
        return false
    end
    local group = self:getGroup()
    return group and group:hasFlag(flag) or false
end

-- Check if the player has premium status
-- @return: True if premium, false otherwise
function Player.isPremium(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isPremium: Invalid player object")
        return false
    end
    return self:getPremiumDays() > 0 or configManager.getBoolean(configKeys.FREE_PREMIUM)
end

-- Check if the player is using an OT client
-- @return: True if using OT client, false otherwise
function Player.isUsingOtClient(self)
    if not isValidPlayer(self) then
        print("[Warning] Player.isUsingOtClient: Invalid player object")
        return false
    end
    local client = self:getClient()
    return client and client.os >= CLIENTOS_OTCLIENT_LINUX
end

-- Section: Banking and Money

-- Deposit money to the player's bank
-- @param amount: The amount to deposit
-- @return: True if successful, false otherwise
function Player.depositMoney(self, amount)
    if not isValidPlayer(self) then
        print("[Warning] Player.depositMoney: Invalid player object")
        return false
    end
    if type(amount) ~= "number" or amount <= 0 then
        print("[Warning] Player.depositMoney: Invalid amount, expected positive number, got " .. tostring(amount))
        return false
    end

    if not self:removeMoney(amount) then
        return false
    end

    self:setBankBalance(self:getBankBalance() + amount)
    return true
end

-- Withdraw money from the player's bank
-- @param amount: The amount to withdraw
-- @return: True if successful, false otherwise
function Player.withdrawMoney(self, amount)
    if not isValidPlayer(self) then
        print("[Warning] Player.withdrawMoney: Invalid player object")
        return false
    end
    if type(amount) ~= "number" or amount <= 0 then
        print("[Warning] Player.withdrawMoney: Invalid amount, expected positive number, got " .. tostring(amount))
        return false
    end

    local balance = self:getBankBalance()
    if amount > balance or not self:addMoney(amount) then
        return false
    end

    self:setBankBalance(balance - amount)
    return true
end

-- Transfer money to another player or account
-- @param target: The target player name or Player object
-- @param amount: The amount to transfer
-- @return: True if successful, false otherwise
function Player.transferMoneyTo(self, target, amount)
    if not isValidPlayer(self) then
        print("[Warning] Player.transferMoneyTo: Invalid player object")
        return false
    end
    if type(amount) ~= "number" or amount <= 0 then
        print("[Warning] Player.transferMoneyTo: Invalid amount, expected positive number, got " .. tostring(amount))
        return false
    end
    if self:getBankBalance() < amount then
        print("[Warning] Player.transferMoneyTo: Insufficient balance")
        return false
    end

    local targetPlayer = Player(target)
    if targetPlayer then
        targetPlayer:setBankBalance(targetPlayer:getBankBalance() + amount)
    else
        if not playerExists(target) then
            print("[Warning] Player.transferMoneyTo: Target player '" .. tostring(target) .. "' does not exist")
            return false
        end
        local query = string.format(
            "UPDATE `players` SET `balance` = `balance` + %d WHERE `name` = %s",
            amount, db.escapeString(tostring(target))
        )
        if not db.query(query) then
            print("[Error] Player.transferMoneyTo: Failed to update target balance")
            return false
        end
    end

    self:setBankBalance(self:getBankBalance() - amount)
    return true
end

-- Section: Messaging and Client Communication

-- Send a cancel message to the player
-- @param message: The message or return message ID
-- @return: True if sent, false otherwise
function Player.sendCancelMessage(self, message)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendCancelMessage: Invalid player object")
        return false
    end
    if message == nil then
        print("[Warning] Player.sendCancelMessage: Message cannot be nil")
        return false
    end

    if type(message) == "number" then
        message = Game.getReturnMessage(message) or "Unknown error"
    end
    return self:sendTextMessage(MESSAGE_STATUS_SMALL, tostring(message))
end

-- Send an extended opcode to OT client users
-- @param opcode: The opcode to send
-- @param buffer: The data buffer (string)
-- @return: True if sent, false otherwise
function Player.sendExtendedOpcode(self, opcode, buffer)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendExtendedOpcode: Invalid player object")
        return false
    end
    if not self:isUsingOtClient() then
        return false
    end
    if type(opcode) ~= "number" or type(buffer) ~= "string" then
        print("[Warning] Player.sendExtendedOpcode: Invalid opcode or buffer")
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(opcode)
    msg:addString(buffer)
    return sendNetworkMessage(self, msg)
end

-- Send healing impact to the client
-- @param healAmount: The amount of healing
-- @return: True if sent, false otherwise
function Player.sendHealingImpact(self, healAmount)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendHealingImpact: Invalid player object")
        return false
    end
    if type(healAmount) ~= "number" or healAmount < 0 then
        print("[Warning] Player.sendHealingImpact: Invalid healAmount, expected non-negative number, got " .. tostring(healAmount))
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xCC)
    msg:addByte(0) -- Healing
    msg:addU32(healAmount)
    return sendNetworkMessage(self, msg)
end

-- Send damage impact to the client
-- @param damage: The amount of damage
-- @return: True if sent, false otherwise
function Player.sendDamageImpact(self, damage)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendDamageImpact: Invalid player object")
        return false
    end
    if type(damage) ~= "number" or damage < 0 then
        print("[Warning] Player.sendDamageImpact: Invalid damage, expected non-negative number, got " .. tostring(damage))
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xCC)
    msg:addByte(1) -- Damage
    msg:addU32(damage)
    return sendNetworkMessage(self, msg)
end

-- Send loot stats for an item
-- @param item: The item object
-- @return: True if sent, false otherwise
function Player.sendLootStats(self, item)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendLootStats: Invalid player object")
        return false
    end
    if not item or not item.getId or not item:getId() then
        print("[Warning] Player.sendLootStats: Invalid item object")
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xCF)
    msg:addItem(item, self)
    msg:addString(getItemName(item:getId()) or "Unknown Item")
    return sendNetworkMessage(self, msg)
end

-- Send waste stats for an item
-- @param item: The item object or item ID
-- @return: True if sent, false otherwise
function Player.sendWaste(self, item)
    if not isValidPlayer(self) then
        print("[Warning] Player.sendWaste: Invalid player object")
        return false
    end

    local itemId
    if type(item) == "number" then
        itemId = item
    elseif item and item.getId then
        itemId = item:getId()
    else
        print("[Warning] Player.sendWaste: Invalid item or item ID")
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xCE)
    msg:addItemId(itemId)
    return sendNetworkMessage(self, msg)
end

-- Section: Skill and Mana Overrides

-- Override skill tries with multiplier control
APPLY_SKILL_MULTIPLIER = true
local addSkillTriesFunc = Player.addSkillTries
function Player.addSkillTries(...)
    APPLY_SKILL_MULTIPLIER = false
    local ret = addSkillTriesFunc(...)
    APPLY_SKILL_MULTIPLIER = true
    return ret
end

-- Override mana spent with multiplier control
local addManaSpentFunc = Player.addManaSpent
function Player.addManaSpent(...)
    APPLY_SKILL_MULTIPLIER = false
    local ret = addManaSpentFunc(...)
    APPLY_SKILL_MULTIPLIER = true
    return ret
end