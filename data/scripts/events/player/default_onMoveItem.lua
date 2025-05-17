local GOLD_POUCH = 26377
local ITEM_STORE_INBOX = 26052
local ITEM_SUPPLY_STASH = 25882
local ITEM_GOLD_COIN = 2148
local ITEM_PLATINUM_COIN = 2152
local ITEM_CRYSTAL_COIN = 2160

local event = Event()
event.onMoveItem = function(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    if toPosition.x ~= CONTAINER_POSITION then
        return RETURNVALUE_NOERROR
    end

    local containerIdFrom = fromPosition.y - 64
    local containerFrom = self:getContainerById(containerIdFrom)
    if containerFrom then
        if (containerFrom:getId() == ITEM_STORE_INBOX or containerFrom:getId() == ITEM_SUPPLY_STASH) and 
           (toPosition.y >= 1 and toPosition.y <= 11 and toPosition.y ~= 3) then
            self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
            return false
        end
    end

    local function getContainerParent(item)
    local parent = item:getParent()
    
    if parent and parent:isContainer() then
        local peekNextParent = parent:getParent()
        if peekNextParent and peekNextParent:isPlayer() then
            return parent
        end
    end
    return false
	end

    local containerTo = self:getContainerById(toPosition.y - 64)
    if containerTo then
        if containerTo:getId() == ITEM_STORE_INBOX or containerTo:getId() == ITEM_SUPPLY_STASH then
            self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
            return false
        end

        if containerTo:getId() == GOLD_POUCH then
            if not (item:getId() == ITEM_CRYSTAL_COIN or
                    item:getId() == ITEM_PLATINUM_COIN or
                    item:getId() == ITEM_GOLD_COIN) then
                self:sendCancelMessage("You can only move money to this container.")
                return false
            end

            local worth = {
                [ITEM_GOLD_COIN] = 1,
                [ITEM_PLATINUM_COIN] = 100,
                [ITEM_CRYSTAL_COIN] = 10000,
            }
            local goldValue = worth[item:getId()]
            if goldValue then
                local newBalance = self:getBankBalance() + (goldValue * item:getCount())
                if item:remove() then
                    self:setBankBalance(newBalance)
                    self:sendTextMessage(MESSAGE_STATUS_DEFAULT, string.format("Your new bank balance is %d gps.", newBalance))
                    return true
                else
                    self:sendCancelMessage("Failed to process the transaction.")
                    return false
                end
            end
        end

        local parentContainer = getContainerParent(containerTo)
        if parentContainer and parentContainer:getId() == ITEM_STORE_INBOX then
            self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
            return false
        end

        local itemType = ItemType(containerTo:getId())
        if itemType:isCorpse() then
            return false
        end
    end

    if item:getId() == GOLD_POUCH then
        self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        return false
    end

    if item:getTopParent() == self and bit.band(toPosition.y, 0x40) == 0 then
        local itemType, moveItem = ItemType(item:getId())
        if bit.band(itemType:getSlotPosition(), SLOTP_TWO_HAND) ~= 0 and toPosition.y == CONST_SLOT_LEFT then
            moveItem = self:getSlotItem(CONST_SLOT_RIGHT)
        elseif itemType:getWeaponType() == WEAPON_SHIELD and toPosition.y == CONST_SLOT_RIGHT then
            moveItem = self:getSlotItem(CONST_SLOT_LEFT)
            if moveItem and bit.band(ItemType(moveItem:getId()):getSlotPosition(), SLOTP_TWO_HAND) == 0 then
                return RETURNVALUE_NOERROR
            end
        end

        if moveItem then
            local parent = item:getParent()
            if parent:isContainer() and parent:getSize() == parent:getCapacity() then
                return RETURNVALUE_CONTAINERNOTENOUGHROOM
            else
                return moveItem:moveTo(parent) and RETURNVALUE_NOERROR or RETURNVALUE_NOTPOSSIBLE
            end
        end
    end

    return RETURNVALUE_NOERROR
end
event:register()