-- Tile Utility Functions for OpenTibia Server

local function isValidTile(tile)
    if not tile or type(tile) ~= "userdata" then
        return false
    end
    local tileObj = Tile(tile)
    if tileObj ~= tile then
        return false
    end
    local pos = tileObj:getPosition()
    return pos and pos.x >= 0 and pos.y >= 0 and pos.z >= 0 and pos.z <= 15
end

local function isValidPosition(pos)
    return pos and type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number"
        and pos.x >= 0 and pos.y >= 0 and pos.z >= 0 and pos.z <= 15
end

function Tile.hasCreature(self)
    if not isValidTile(self) then
        return false
    end
    return false
end

function Tile.hasItem(self)
    if not isValidTile(self) then
        return false
    end
    return false
end

function Tile.isTile(self)
    if not isValidTile(self) then
        return false
    end
    return true
end

function Tile.isContainer(self)
    if not isValidTile(self) then
        return false
    end
    return false
end

function Tile.relocateTo(self, toPosition)
    if not isValidTile(self) or not isValidPosition(toPosition) then
        return false
    end

    local currentPos = self:getPosition()
    if currentPos == toPosition then
        return false
    end

    local destTile = Tile(toPosition)
    if not isValidTile(destTile) then
        return false
    end

    local creatures = self:getCreatures() or {}
    for _, creature in ipairs(creatures) do
        if creature and creature:isCreature() then
            creature:teleportTo(toPosition)
        end
    end

    local items = self:getItems() or {}
    for _, item in ipairs(items) do
        if item and item:isItem() then
            if item:getFluidType() ~= 0 then
                item:remove()
            else
                local itemType = ItemType(item:getId())
                if itemType and itemType:isMovable() then
                    item:moveTo(toPosition)
                end
            end
        end
    end

    return true
end

function Tile.isWalkable(self)
    if not isValidTile(self) then
        return false
    end

    local ground = self:getGround()
    if not ground or ground:hasProperty(CONST_PROP_BLOCKSOLID) then
        return false
    end

    local items = self:getItems() or {}
    for _, item in ipairs(items) do
        local itemType = item:getType()
        if itemType and itemType:getType() ~= ITEM_TYPE_MAGICFIELD and not itemType:isMovable() and item:hasProperty(CONST_PROP_BLOCKSOLID) then
            return false
        end
    end

    return true
end