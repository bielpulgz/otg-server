-- Função auxiliar para formatar a duração dos imbuements
function getTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local timeStr = ""
    if hours > 0 then
        timeStr = string.format("%dh", hours)
    end
    if minutes > 0 then
        timeStr = timeStr .. (hours > 0 and " " or "") .. string.format("%dm", minutes)
    end
    return timeStr ~= "" and timeStr or "0m"
end

local event = Event()
event.onLook = function(self, thing, position, distance, description)
    local description = "You see " .. thing:getDescription(distance)
    if self:getGroup():getAccess() then
        if thing:isItem() then
            description = string.format("%s\nItem ID: %d", description, thing:getId())

            local actionId = thing:getActionId()
            if actionId ~= 0 then
                description = string.format("%s, Action ID: %d", description, actionId)
            end

            local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
            if uniqueId > 0 and uniqueId < 65536 then
                description = string.format("%s, Unique ID: %d", description, uniqueId)
            end

            local itemType = thing:getType()
            if itemType and itemType:getImbuingSlots() > 0 then
                local imbuingSlots = "Imbuements: ("
                for slot = 0, itemType:getImbuingSlots() - 1 do
                    if slot > 0 then
                        imbuingSlots = string.format("%s, ", imbuingSlots)
                    end
                    local duration = thing:getImbuementDuration(slot)
                    if duration > 0 then
                        local imbue = thing:getImbuement(slot)
                        imbuingSlots = string.format("%s%s %s %s", imbuingSlots, imbue:getBase().name, imbue:getName(), getTime(duration))
                    else
                        imbuingSlots = string.format("%sEmpty Slot", imbuingSlots)
                    end
                end
                imbuingSlots = string.format("%s).", imbuingSlots)
                description = string.gsub(description, "It weighs", imbuingSlots .. "\nIt weighs")
            end

            local transformEquipId = itemType:getTransformEquipId()
            local transformDeEquipId = itemType:getTransformDeEquipId()
            if transformEquipId ~= 0 then
                description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
            elseif transformDeEquipId ~= 0 then
                description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
            end

            local decayId = itemType:getDecayId()
            if decayId ~= -1 then
                description = string.format("%s\nDecays to: %d", description, decayId)
            end
        elseif thing:isCreature() then
            local str = "%s\nHealth: %d / %d"
            if thing:isPlayer() and thing:getMaxMana() > 0 then
                str = string.format("%s, Mana: %d / %d", str, thing:getMana(), thing:getMaxMana())
            end
            description = string.format(str, description, thing:getHealth(), thing:getMaxHealth())

            description = string.format("%s\nSpeed: %d", description, thing:getSpeed())

            if thing:isPlayer() then
                description = string.format("%s\nIP: %s", description, Game.convertIpToString(thing:getIp()))

                local client = thing:getClient()
                local clientOS = client.os
                local clientName = "Unknown"
                if clientOS == 2 then
                    clientName = "Tibia Cipsoft 10x"
                elseif clientOS == 10 then
                    clientName = "isMehah"
                elseif clientOS == 20 then
                    clientName = "OTCv8"
                elseif clientOS > 0 then
                    clientName = "Other OTC (" .. clientOS .. ")"
                end
                description = string.format("%s\nClient: %s", description, clientName)
            end
        end

        local position = thing:getPosition()
        description = string.format(
            "%s\nPosition: %d, %d, %d",
            description, position.x, position.y, position.z
        )
    end
    return description
end

event:register()