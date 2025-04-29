-- Imbuement System Configuration and Logic

-- Message dialog types for imbuement operations
local IMBUEMENT_MESSAGE_TYPES = {
    IMBUEMENT_ERROR = 1,
    IMBUEMENT_ROLL_FAILED = 2,
    IMBUING_STATION_NOT_FOUND = 3,
    CLEARING_CHARM_SUCCESS = 10,
    CLEARING_CHARM_ERROR = 11
}

-- Equipment types and their corresponding item IDs
local IMBUEMENT_EQUIPMENT_TYPES = {
    armor = {33911, 33916, 33221, 21692, 2500, 2656, 2464, 2487, 2494, 15407, 2492, 2503, 12607, 2505, 32419, 30883, 2466, 23538, 10296, 2476, 3968, 2472, 7463, 8888, 23537, 2486, 15406, 8891, 18404},
    shield = {33224, 2537, 2518, 15491, 2535, 2519, 25414, 2520, 15411, 2516, 32422, 32421, 30885, 2522, 2533, 21707, 2514, 10289, 2536, 6433, 6391, 7460, 2524, 15413, 2539, 25382, 21697, 3974, 10297, 12644, 10294, 2509, 2542, 2528, 2534, 2531, 15453},
    boots = {36331, 33917, 35108, 2358, 24742, 2195, 2644, 9931, 3982, 11117, 15410, 11118, 12646, 7457, 7892, 2646, 11240, 2643, 7893, 7891, 23540, 24637, 2641, 5462, 18406, 2642, 2645, 7886, 25412, 21708, 11303},
    helmet = {33217, 2499, 2139, 3972, 2458, 2491, 2497, 2493, 2502, 12645, 32415, 7458, 2471, 10299, 20132, 10298, 2662, 10291, 2498, 24848, 5741, 25410, 2475, 11302},
    helmetmage = {33216, 10016, 2323, 11368, 8820, 10570, 9778, 30882},
    bow = {33910, 33220, 30690, 8855, 7438, 32418, 15643, 21696, 10295, 18454, 25522, 8857, 22417, 22418, 8854},
    crossbow = {35107, 8850, 2455, 30691, 8849, 25523, 8851, 8852, 8853, 16111, 21690, 22420, 22421},
    backpack = {1988, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2365, 3940, 3960, 5801, 5926, 5949, 7342, 9774, 10518, 10519, 10521, 10522, 11119, 11241, 11243, 11244, 11263, 15645, 15646, 16007, 18393, 18394, 21475, 22696, 23666, 23816, 24740, 26181, 27061, 27063, 35056},
    wand = {35113, 29005, 2191, 8920, 8921, 8922},
    rod = {35114, 8910, 8911, 24839},
    axe = {35110, 30686, 2429, 3962, 7412, 30687, 18451, 8926, 2414, 11305, 7419, 2435, 7453, 2415, 2427, 7380, 8924, 7389, 15492, 7435, 2430, 7455, 7456, 2443, 25383, 7434, 6553, 8925, 2431, 2447, 22405, 22408, 22406, 22409, 2454, 15451, 11323},
    club = {33912, 33227, 35109, 7414, 7426, 2453, 7429, 2423, 7415, 2445, 15647, 7431, 7430, 23543, 30689, 2444, 2452, 20093, 7424, 30688, 25418, 18452, 8928, 7421, 7392, 15414, 7410, 7437, 7451, 2424, 2436, 7423, 12648, 7452, 8929, 22414, 22411, 22415, 22412, 2421, 2391},
    sword = {33914, 33915, 33225, 35112, 7404, 7403, 7406, 12649, 30684, 7416, 2407, 2413, 7385, 7382, 2451, 7402, 8930, 2438, 2393, 30886, 7407, 7405, 2400, 7384, 7418, 7383, 7417, 18465, 30685, 2383, 2376, 7391, 6528, 8931, 12613, 11309, 22399, 22403, 22400, 22402, 7408, 11307},
    spellbooks = {25411, 2175, 8900, 8901, 22423, 22424, 29004, 33924, 33913, 33919},
    especial = {30692, 30693, 33219, 33218, 33305, 33304, 33918, 33226}
}

-- Imbuement compatibility with equipment types
local IMBUEMENT_COMPATIBILITY = {
    ["lich shroud"] = {"armor", "spellbooks", "shield"},
    ["reap"] = {"axe", "club", "sword"},
    ["vampirism"] = {"axe", "club", "sword", "wand", "rod", "especial", "bow", "crossbow", "armor"},
    ["cloud fabric"] = {"armor", "spellbooks", "shield"},
    ["electrify"] = {"axe", "club", "sword"},
    ["swiftness"] = {"boots"},
    ["snake skin"] = {"armor", "spellbooks", "shield"},
    ["venom"] = {"axe", "club", "sword"},
    ["slash"] = {"sword", "helmet"},
    ["chop"] = {"axe", "helmet"},
    ["bash"] = {"club", "helmet"},
    ["hide dragon"] = {"armor", "spellbooks", "shield"},
    ["scorch"] = {"axe", "club", "sword"},
    ["void"] = {"axe", "club", "sword", "wand", "rod", "especial", "bow", "crossbow", "helmet", "helmetmage"},
    ["quara scale"] = {"armor", "spellbooks", "shield"},
    ["frost"] = {"axe", "club", "sword"},
    ["blockade"] = {"shield", "helmet", "spellbooks"},
    ["demon presence"] = {"armor", "spellbooks", "shield"},
    ["precision"] = {"bow", "crossbow", "helmet"},
    ["strike"] = {"axe", "club", "sword", "bow", "crossbow", "especial"},
    ["epiphany"] = {"wand", "rod", "helmetmage", "especial"},
    ["featherweight"] = {"backpack"}
}

-- Helper function to check if an item ID belongs to a specific equipment type
local function getEquipmentType(itemId)
    if type(itemId) ~= "number" then
        return nil
    end
    for equipType, items in pairs(IMBUEMENT_EQUIPMENT_TYPES) do
        if isInArray(items, itemId) then
            return equipType
        end
    end
    return nil
end

-- Player function to check if an item can be imbued with a specific imbuement
function Player.canImbueItem(self, imbuement, item)
    if not self or not imbuement or not item then
        print("[Warning] Player.canImbueItem: Invalid arguments provided")
        return false
    end

    -- Validate imbuement
    if not imbuement.getName or not imbuement:getName() then
        print("[Warning] Player.canImbueItem: Invalid imbuement object")
        return false
    end

    -- Validate item
    if not item.getId or not item:getId() then
        print("[Warning] Player.canImbueItem: Invalid item object")
        return false
    end

    -- Get equipment type for the item
    local itemType = getEquipmentType(item:getId())
    if not itemType then
        print("[Warning] Player.canImbueItem: Item ID " .. tostring(item:getId()) .. " is not imbuable")
        return false
    end

    -- Get imbuement name and compatible equipment types
    local imbueName = imbuement:getName():lower()
    local compatibleTypes = IMBUEMENT_COMPATIBILITY[imbueName]
    if not compatibleTypes then
        print("[Warning] Player.canImbueItem: Imbuement '" .. imbueName .. "' not found in compatibility table")
        return false
    end

    -- Check if the item type is compatible with the imbuement
    for _, compatibleType in ipairs(compatibleTypes) do
        if compatibleType:lower() == itemType then
            return true
        end
    end

    return false
end

-- Player function to send imbuement result message
function Player.sendImbuementResult(self, errorType, message)
    if not self or not message or type(message) ~= "string" or message == "" then
        print("[Warning] Player.sendImbuementResult: Invalid player or message")
        return false
    end

    errorType = errorType or IMBUEMENT_MESSAGE_TYPES.IMBUEMENT_ERROR
    if not IMBUEMENT_MESSAGE_TYPES[errorType] then
        print("[Warning] Player.sendImbuementResult: Invalid errorType, defaulting to IMBUEMENT_ERROR")
        errorType = IMBUEMENT_MESSAGE_TYPES.IMBUEMENT_ERROR
    end

    local msg = NetworkMessage()
    msg:addByte(0xED)
    msg:addByte(errorType)
    msg:addString(message)
    msg:sendToPlayer(self)
    msg:delete()
    return true
end

-- Player function to close imbuement window
function Player.closeImbuementWindow(self)
    if not self then
        print("[Warning] Player.closeImbuementWindow: Invalid player")
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xEC)
    msg:sendToPlayer(self)
    msg:delete()
    return true
end

-- Item function to get imbuement duration for a slot
function Item.getImbuementDuration(self, slot)
    if not self or type(slot) ~= "number" or slot < 0 then
        print("[Warning] Item.getImbuementDuration: Invalid item or slot")
        return 0
    end

    local binfo = tonumber(self:getCustomAttribute(IMBUEMENT_SLOT + slot)) or 0
    return bit.rshift(binfo, 8)
end

-- Item function to get imbuement details for a slot
function Item.getImbuement(self, slot)
    if not self or type(slot) ~= "number" or slot < 0 then
        print("[Warning] Item.getImbuement: Invalid item or slot")
        return false
    end

    local binfo = tonumber(self:getCustomAttribute(IMBUEMENT_SLOT + slot)) or 0
    local id = bit.band(binfo, 0xFF)
    if id == 0 then
        return false
    end

    local duration = bit.rshift(binfo, 8)
    if duration <= 0 then
        return false
    end

    local imbuement = Imbuement(id)
    if not imbuement then
        print("[Warning] Item.getImbuement: Invalid imbuement ID " .. id)
        return false
    end

    return imbuement
end

-- Item function to add an imbuement to a slot
function Item.addImbuement(self, slot, id, duration)
    if not self or type(slot) ~= "number" or slot < 0 or type(id) ~= "number" then
        print("[Warning] Item.addImbuement: Invalid item, slot, or ID")
        return false
    end

    local imbuement = Imbuement(id)
    if not imbuement then
        print("[Warning] Item.addImbuement: Invalid imbuement ID " .. id)
        return false
    end

    duration = duration or (imbuement:getBase() and imbuement:getBase().duration) or 0
    if type(duration) ~= "number" or duration <= 0 then
        print("[Warning] Item.addImbuement: Invalid duration for imbuement ID " .. id)
        return false
    end

    local imbue = bit.bor(bit.lshift(duration, 8), id)
    self:setCustomAttribute(IMBUEMENT_SLOT + slot, imbue)
    return true
end

-- Item function to clear an imbuement from a slot
function Item.cleanImbuement(self, slot)
    if not self or type(slot) ~= "number" or slot < 0 then
        print("[Warning] Item.cleanImbuement: Invalid item or slot")
        return false
    end

    self:setCustomAttribute(IMBUEMENT_SLOT + slot, 0)
    return true
end