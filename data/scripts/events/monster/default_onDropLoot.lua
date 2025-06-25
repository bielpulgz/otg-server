local event = Event()
event.onDropLoot = function(self, corpse)
    if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
        return
    end
    
    local mType = self:getType()
    if mType:isRewardBoss() then
        corpse:registerReward()
        return
    end
    
    local player = Player(corpse:getCorpseOwner())
    local percent = 1.0
    
    local bonusPrey = 0
    local hasCharm = false
    
    -- Prey and bonus system
    if player then
        -- Prey bonus loot
        local random = (player:getPreyBonusLoot(mType) >= math.random(100))
        if player:getPreyBonusLoot(mType) > 0 and random then
            bonusPrey = player:getPreyBonusLoot(mType)
            percent = percent + (bonusPrey / 100)
        end
        
        -- Client version bonus
        if player:getClient().version >= 1200 then
            percent = percent + 0.05
        end
        
        -- Guild Level System
        local g = player:getGuild()
        if g then
            local rewards = getReward(player:getId()) or {}
            for i = 1, #rewards do
                if rewards[i].type == GUILD_LEVEL_BONUS_LOOT then
                    percent = percent + rewards[i].quantity
                    break
                end
            end
        end
        
        -- charm - TEMPORARILY DISABLED (raceId() method not available)
        -- TODO: Re-enable when raceId() method is implemented
        --[[
        local currentCharm = player:getMonsterCharm(mType:raceId())
        if currentCharm == 14 then
            percent = percent * 1.10
            hasCharm = true
        end
        --]]
        
        -- Premium bonus
        if player:isPremium() then
            percent = percent * 1.05
        end
    end
    
    -- Loot creation (based on original working code)
    if not player or player:getStamina() > 840 then
        local monsterLoot = mType:getLoot()
        for i = 1, #monsterLoot do
            local item = corpse:createLootItem(monsterLoot[i])
            if not item then
                print('[Warning] DropLoot:', 'Could not add loot item to corpse.')
            end
        end

        if player then
            if player:getClient().os == CLIENTOS_NEW_WINDOWS then
                local text = ("Loot of %s: %s."):format(mType:getNameDescription(), corpse:getContentDescriptionColor())
                local party = player:getParty()
                if party then
                    party:broadcastPartyLoot(text)
                else
                    player:sendTextMessage(MESSAGE_LOOT, text)
                end
            else
                local text = ("Loot of %s: %s."):format(mType:getNameDescription(), corpse:getContentDescription())
                local party = player:getParty()
                if party then
                    party:broadcastPartyLoot(text)
                else
                    player:sendTextMessage(MESSAGE_LOOT, text)
                end
            end
            player:updateKillTracker(self, corpse)
        end
    else
        local text = ("Loot of %s: nothing (due to low stamina)"):format(mType:getNameDescription())
        local party = player:getParty()
        if party then
            party:broadcastPartyLoot(text)
        else
            player:sendTextMessage(MESSAGE_LOOT, text)
        end
    end
end
event:register()