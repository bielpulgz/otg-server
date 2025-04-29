-- Tile Utility Functions for OpenTibia Server

-- Helper function to validate Tile object
local function isValidTile(tile)
    return tile and type(tile) == "userdata" and tile.isTile and tile:isTile()
end

-- Helper function to validate Position object
local function isValidPosition(pos)
    return pos and type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number"
end

-- Section: Type and Content Checks

-- Check if the tile contains a creature
-- @return: False (base implementation, override if creatures are present)
function Tile.hasCreature(self)
    if not isValidTile(self) then
        print("[Warning] Tile.hasCreature: Invalid tile object")
        return false
    end
    return false
end

-- Check if the tile contains an item
-- @return: False (base implementation, override if items are present)
function Tile.hasItem(self)
    if not isValidTile(self) then
        print("[Warning] Tile.hasItem: Invalid tile object")
        return false
    end
    return false
end

-- Confirm that the object is a tile
-- @return: True
function Tile.isTile(self)
    if not isValidTile(self) then
        print("[Warning] Tile.isTile: Invalid tile object")
        return false
    end
    return true
end

-- Check if the tile is a container
-- @return: False (base implementation, override if container)
function Tile.isContainer(self)
    if not isValidTile(self) then
        print("[Warning] Tile.isContainer: Invalid tile object")
        return false
    end
    return false
end

-- Section: Tile Manipulation

-- Relocate all movable things on the tile to a new position
-- @param toPosition: The destination position (table with x, y, z)
-- @return: True if relocation was successful, false otherwise
function Tile.relocateTo(self, toPosition)
    if not isValidTile(self) then
        print("[Warning] Tile.relocateTo: Invalid tile object")
        return false
    end
    if not isValidPosition(toPosition) then
        print("[Warning] Tile.relocateTo: Invalid toPosition")
        return false
    end

    local currentPos = self:getPosition()
    if currentPos == toPosition then
        return false
    end

    local destTile = Tile(toPosition)
    if not destTile then
        print("[Warning] Tile.relocateTo: Destination tile does not exist at " .. tostring(toPosition))
        return false
    end

    -- Process creatures first
    local creatures = self:getCreatures() or {}
    for _, creature in ipairs(creatures) do
        if creature and creature:isCreature() then
            creature:teleportTo(toPosition)
        end
    end

    -- Process items
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

-- Section: Tile Properties

-- Check if the tile is walkable
-- @return: True if walkable, false otherwise
function Tile.isWalkable(self)
    if not isValidTile(self) then
        print("[Warning] Tile.isWalkable: Invalid tile object")
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