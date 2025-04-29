function Player:onLook(thing, position, distance)
	local description = ""
	if hasEvent.onLook then
		description = Event.onLook(self, thing, position, distance, description)
	end
	
	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInBattleList(creature, distance)
	local description = ""
	if hasEvent.onLookInBattleList then
		description = Event.onLookInBattleList(self, creature, distance, description)
	end
	
	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	if hasEvent.onLookInTrade then
		description = Event.onLookInTrade(self, partner, item, distance, description)
	end

	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
	return true
end

function Player:onLookInShop(itemType, count)
	local description = "You see " .. description
	if hasEvent.onLookInShop then
		description = Event.onLookInShop(self, itemType, count, description)
	end
	
	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
	return true
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEvent.onMoveItem then
		return Event.onMoveItem(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
	return true
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEvent.onItemMoved then
		Event.onItemMoved(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if hasEvent.onMoveCreature then
		return Event.onMoveCreature(self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if hasEvent.onReportRuleViolation then
		Event.onReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	if hasEvent.onReportBug then
		return Event.onReportBug(self, message, position, category)
	end
	return true
end

function Player:onTurn(direction)
    if hasEvent.onTurn then
		return Event.onTurn(self, direction)
	end
    return true
end

function Player:onTradeRequest(target, item)
	if hasEvent.onTradeRequest then
		return Event.onTradeRequest(self, target, item)
	end
	self:closeImbuementWindow(target)
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	if hasEvent.onTradeAccept then
		return Event.onTradeAccept(self, target, item, targetItem)
	end
	self:closeImbuementWindow(target)
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEvent.onTradeCompleted then
		return Event.onTradeCompleted(target, item, targetItem, isSuccess)
	end
	return true
end

function Player:onGainExperience(source, exp, rawExp, sendText)
	return hasEvent.onGainExperience and Event.onGainExperience(self, source, exp, rawExp, sendText) or exp
end

function Player:onLoseExperience(exp)
	return hasEvent.onLoseExperience and Event.onLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	if not APPLY_SKILL_MULTIPLIER then
		return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
	return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
end

function Player:onSay(message)
	if hasEvent.onSay then
		Event.onSay(self, message)
		return true
	end
end

function Player:onStepTile(fromPosition, toPosition)
    if hasEvent.onStepTile then
        return Event.onStepTile(self, fromPosition, toPosition)
    end
    return true
end

function Player:onSpellCheck(spell)
	if hasEvent.onSpellCheck then
		return Event.onSpellCheck(self, spell)
	end
	return true
end

function Player:canBeAppliedImbuement(imbuement, item)
	if hasEvent.canBeAppliedImbuement and not Event.canBeAppliedImbuement(self, imbuement, item) then
		return false
	end
	return true
end

function Player:onApplyImbuement(imbuement, item, slot, protectionCharm)
	if hasEvent.onApplyImbuement and not Event.onApplyImbuement(self, imbuement, item, slot, protectionCharm) then
		return false
	end
	return true
end

function Player:clearImbuement(item, slot)
	if hasEvent.clearImbuement and not Event.clearImbuement(self, item, slot) then
		return false
	end
	return true
end


function Player:onCombat(target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if hasEvent.onCombat then
		return Event.onCombat(self, target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	end
end

function Player:onWrapItem(item)
    local topCylinder = item:getTopParent()
    if not topCylinder then
        return
    end

    local tile = Tile(topCylinder:getPosition())
    if not tile then
        return
    end

    local house = tile:getHouse()
    if not house then
        self:sendCancelMessage("You can only wrap and unwrap this item inside a house.")
        return
    end

    if house ~= self:getHouse() and not string.find(house:getAccessList(SUBOWNER_LIST):lower(), "%f[%a]" .. self:getName():lower() .. "%f[%A]") then
        self:sendCancelMessage("You cannot wrap or unwrap items from a house, which you are only guest to.")
        return
    end

    local wrapId = item:getAttribute("wrapid")
    if wrapId == 0 then
        return
    end

  if not hasEvent.onWrapItem or Event.onWrapItem(self, item) then
        local oldId = item:getId()
        item:remove(1)
        local item = tile:addItem(wrapId)
        if item then
            item:setAttribute("wrapid", oldId)
        end
    end
end

function Player:onInventoryUpdate(item, slot, equip)
	if hasEvent.onInventoryUpdate then
		Event.onInventoryUpdate(self, item, slot, equip)
	end
end

function Player:onNetworkMessage(recvByte, msg)
	local handler = PacketHandlers[recvByte]
	if not handler then
		--io.write(string.format("Player: %s sent an unknown packet header: 0x%02X with %d bytes!\n", self:getName(), recvByte, msg:len()))
		return
	end

	handler(self, msg)
end

function Player:onUpdateStorage(key, value, oldValue, isLogin)
	if hasEvent.onUpdateStorage then
		Event.onUpdateStorage(self, key, value, oldValue, isLogin)
	end
end