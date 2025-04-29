-- Monster Storage and Shared Life System

-- Initialize global storage for monster-specific data
local monsterStorage = monsterStorage or {}

-- Initialize global storage for shared life pools
local hpCompartilhada = hpCompartilhada or {}

-- Helper function to validate monster object
local function isValidMonster(monster)
    return monster and monster:isMonster() and monster.getId and monster:getId() > 0
end

-- Helper function to clean up dead monsters from storage
local function cleanupMonsterStorage(monsterId)
    if monsterStorage[monsterId] then
        monsterStorage[monsterId] = nil
        print("[Info] MonsterStorage: Cleaned up storage for monster ID " .. monsterId)
    end
end

-- Helper function to clean up monster from shared life pool
local function cleanupSharedLife(monsterId)
    for hpid, data in pairs(hpCompartilhada) do
        for i, mid in ipairs(data.monsters) do
            if mid == monsterId then
                table.remove(data.monsters, i)
                print("[Info] SharedLife: Removed monster ID " .. monsterId .. " from pool " .. hpid)
                if #data.monsters == 0 then
                    hpCompartilhada[hpid] = nil
                    print("[Info] SharedLife: Cleaned up empty pool " .. hpid)
                end
                return
            end
        end
    end
end

-- Get a storage value for a monster
-- @param key: The storage key (number or string)
-- @return: The stored value or -1 if not found
function Monster.getStorageValue(self, key)
    if not isValidMonster(self) then
        print("[Warning] Monster.getStorageValue: Invalid monster object")
        return -1
    end
    if key == nil then
        print("[Warning] Monster.getStorageValue: Key cannot be nil")
        return -1
    end

    local monsterId = self:getId()
    if not monsterStorage[monsterId] or not monsterStorage[monsterId][key] then
        return -1
    end

    return monsterStorage[monsterId][key]
end

-- Set a storage value for a monster
-- @param key: The storage key (number or string)
-- @param value: The value to store
-- @return: True if successful, false otherwise
function Monster.setStorageValue(self, key, value)
    if not isValidMonster(self) then
        print("[Warning] Monster.setStorageValue: Invalid monster object")
        return false
    end
    if key == nil then
        print("[Warning] Monster.setStorageValue: Key cannot be nil")
        return false
    end

    local monsterId = self:getId()
    monsterStorage[monsterId] = monsterStorage[monsterId] or {}
    monsterStorage[monsterId][key] = value
    return true
end

-- Alias for getStorageValue
function Monster.getStorage(self, key)
    return self:getStorageValue(key)
end

-- Alias for setStorageValue
function Monster.setStorage(self, key, value)
    return self:setStorageValue(key, value)
end

-- Initialize a monster in a shared life pool
-- @param hpid: The shared life pool ID (number)
-- @return: True if successful, false otherwise
function Monster.beginSharedLife(self, hpid)
    if not isValidMonster(self) then
        print("[Warning] Monster.beginSharedLife: Invalid monster object")
        return false
    end
    if type(hpid) ~= "number" or hpid < 1 then
        print("[Warning] Monster.beginSharedLife: Invalid hpid, expected positive number, got " .. tostring(hpid))
        return false
    end

    local monsterId = self:getId()
    hpCompartilhada[hpid] = hpCompartilhada[hpid] or {hp = self:getMaxHealth(), monsters = {}}

    -- Avoid duplicate entries
    for _, mid in ipairs(hpCompartilhada[hpid].monsters) do
        if mid == monsterId then
            return true
        end
    end

    table.insert(hpCompartilhada[hpid].monsters, monsterId)
    self:setStorageValue("shared_storage", hpid)
    print("[Info] Monster.beginSharedLife: Monster ID " .. monsterId .. " added to pool " .. hpid)
    return true
end

-- Check if a monster is in a shared life pool
-- @return: True if in shared life, false otherwise
function Monster.inSharedLife(self)
    if not isValidMonster(self) then
        print("[Warning] Monster.inSharedLife: Invalid monster object")
        return false
    end

    local storage = self:getStorageValue("shared_storage")
    if storage < 1 then
        return false
    end

    local monsterId = self:getId()
    if hpCompartilhada[storage] then
        for _, mid in ipairs(hpCompartilhada[storage].monsters) do
            if mid == monsterId then
                return true
            end
        end
    end

    -- Clean up invalid storage reference
    self:setStorageValue("shared_storage", -1)
    return false
end

-- Update shared life for all monsters in a pool
-- @param hpid: The shared life pool ID
-- @param amount: The amount to adjust HP (positive for healing, negative for damage)
-- @param originId: The ID of the monster triggering the update
-- @param actionType: "healing" or "damage"
-- @param kill: True to kill all monsters in the pool
-- @return: True if successful, false otherwise
function updateMonstersSharedLife(hpid, amount, originId, actionType, kill)
    if type(hpid) ~= "number" or not hpCompartilhada[hpid] then
        print("[Warning] updateMonstersSharedLife: Invalid or non-existent pool ID " .. tostring(hpid))
        return false
    end
    if type(amount) ~= "number" then
        print("[Warning] updateMonstersSharedLife: Invalid amount, expected number, got " .. tostring(amount))
        return false
    end

    -- Update shared HP
    if actionType == "healing" then
        hpCompartilhada[hpid].hp = math.min(hpCompartilhada[hpid].hp + amount, hpCompartilhada[hpid].hp)
    else
        hpCompartilhada[hpid].hp = math.max(hpCompartilhada[hpid].hp - amount, 0)
    end

    -- Update all monsters in the pool
    local deadMonsters = {}
    for _, monsterId in ipairs(hpCompartilhada[hpid].monsters) do
        if monsterId ~= originId then
            local monster = Monster(monsterId)
            if monster and isValidMonster(monster) then
                if kill or hpCompartilhada[hpid].hp == 0 then
                    monster:addHealth(-monster:getHealth())
                else
                    monster:setHealth(hpCompartilhada[hpid].hp)
                end
            else
                table.insert(deadMonsters, monsterId)
            end
        end
    end

    -- Clean up dead monsters
    for _, monsterId in ipairs(deadMonsters) do
        cleanupSharedLife(monsterId)
        cleanupMonsterStorage(monsterId)
    end

    return true
end

-- Handle damage or healing for monsters in shared life
-- @param damage: The amount of damage or healing
-- @param actionType: "healing" or "damage"
-- @param killer: True if the action should kill the monster
-- @return: True if processed, false otherwise
function Monster.onReceivDamageSL(self, damage, actionType, killer)
    if not isValidMonster(self) then
        print("[Warning] Monster.onReceivDamageSL: Invalid monster object")
        return false
    end
    if not self:inSharedLife() then
        return true
    end

    local storage = self:getStorageValue("shared_storage")
    if storage < 1 then
        print("[Warning] Monster.onReceivDamageSL: Invalid shared storage value")
        return false
    end

    return updateMonstersSharedLife(storage, damage, self:getId(), actionType, killer)
end