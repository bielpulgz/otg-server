-- Daily Reward System for OpenTibia Server
-- Manages daily rewards, streaks, and resting area bonuses for players.

-- Constants for Reward Types
REWARD_TYPE_RUNE_POT = 1
REWARD_TYPE_PREY_REROLL = 2
REWARD_TYPE_TEMPORARYITEM = 3
REWARD_TYPE_XP_BOOST = 4

-- Modal State Constants
MODAL_STATE_MAINMENU = 1
MODAL_STATE_VIEWDAILYREWARD_LANE = 2
MODAL_STATE_VIEWSTREAKBONUSES_INDEX = 3
MODAL_STATE_VIEWSTREAKBONUSES_DETAILS = 4
MODAL_STATE_SELECTING_REWARD_ITEMS = 5
MODAL_STATE_CONFIRM_REWARD_PICK = 6
MODAL_STATE_VIEWREWARDHISTORY = 7
MODAL_STATE_VIEWREWARDHISTORY_DETAILS = 8

-- Global State and Cache
local dailyRewardStates = {}
local itemsCache = {}

-- Potion IDs for Rewards
local potionsIds = {7588, 7589, 7590, 7591, 7618, 7620, 8472, 8473, 26029, 26030, 26031}

-- Reward Shrine IDs
local rewardShrineIds = {29021, 29022, 29023, 29024, 29089, 29090}

-- Reward Lanes for Free and Premium Accounts
REWARD_LANE = {
    FREE_ACC = {
        {
            description = "Choose 5 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 5,
            available = {}
        },
        {
            description = "Choose 5 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 5,
            available = {}
        },
        {
            description = "One Prey Bonus Reroll",
            type = REWARD_TYPE_PREY_REROLL,
            ammount = 1
        },
        {
            description = "Choose 10 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {}
        },
        {
            description = "Choose 10 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {}
        },
        {
            description = "One temporary Gold Converter with 100 charges",
            type = REWARD_TYPE_TEMPORARYITEM,
            ammount = 1,
            items = {{id = 29015, ammount = 100}},
            expires = true
        },
        {
            description = "Ten minutes 50% XP Boost",
            type = REWARD_TYPE_XP_BOOST,
            ammount = 10,
            expires = true
        }
    },
    PREMIUM_ACC = {
        {
            description = "Choose 10 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {}
        },
        {
            description = "Choose 10 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 10,
            available = {}
        },
        {
            description = "Two Prey Bonus Rerolls",
            type = REWARD_TYPE_PREY_REROLL,
            ammount = 2
        },
        {
            description = "Choose 20 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 20,
            available = {}
        },
        {
            description = "Choose 20 runes or potions",
            type = REWARD_TYPE_RUNE_POT,
            ammount = 20,
            available = {}
        },
        {
            description = "One temporary Temple Teleport scroll and one temporary Gold Converter with 100 charges",
            type = REWARD_TYPE_TEMPORARYITEM,
            ammount = 1,
            expires = true,
            items = {
                {id = 29020, ammount = 100},
                {id = 29019, ammount = 1}
            }
        },
        {
            description = "Thirty minutes 50% XP Boost",
            type = REWARD_TYPE_XP_BOOST,
            ammount = 30,
            expires = true
        }
    }
}

-- Reward Streaks for Resting Area Bonuses
REWARD_STREAK = {
    {
        days = 2,
        description = "Allow hitpoints regeneration",
        fullDescription = "This bonus grants you the ability to regenerate your hitpoints inside resting areas (affects all health regeneration from items/food)."
    },
    {
        days = 3,
        description = "Allow mana regeneration",
        fullDescription = "This bonus grants you the ability to regenerate your mana inside resting areas (affects all mana regeneration from items/food)."
    },
    {
        days = 4,
        description = "Stamina regeneration",
        fullDescription = "This bonus grants you the ability to regenerate your stamina inside resting areas, similar to being logged out.\n" ..
                        "If your stamina is below 40 hours, you recover 1 stamina minute every 3 minutes.\n" ..
                        "If over 40 hours, you recover 1 stamina minute every 10 minutes.",
        premium = true
    },
    {
        days = 5,
        description = "Double hitpoints regeneration",
        fullDescription = "Your current hitpoint regeneration inside resting areas is doubled (affects all health regeneration from items/food).",
        premium = true
    },
    {
        days = 6,
        description = "Double mana regeneration",
        fullDescription = "Your current mana regeneration inside resting areas is doubled (affects all mana regeneration from items/food).",
        premium = true
    },
    {
        days = 7,
        description = "Soul Points regeneration",
        fullDescription = "This bonus grants you the ability to regenerate soul points inside resting areas, similar to killing creatures.\n" ..
                        "- Regular characters regenerate 1 soul point every 2 minutes.\n" ..
                        "- Promoted characters regenerate 1 soul point every 15 seconds.",
        premium = true
    }
}

-- Helper function to validate player
local function isValidPlayer(player)
    return player and player:isPlayer() and player:getId() > 0
end

-- Convert seconds to hours
-- @param seconds: Time in seconds
-- @return: Hours
local function getHours(seconds)
    return math.floor((seconds / 60) / 60)
end

-- Convert seconds to minutes
-- @param seconds: Time in seconds
-- @return: Minutes
local function getMinutes(seconds)
    return math.floor(seconds / 60)
end

-- Get remaining seconds
-- @param seconds: Time in seconds
-- @return: Seconds
local function getSeconds(seconds)
    return seconds % 60
end

-- Format time into a human-readable string
-- @param secs: Time in seconds
-- @return: Formatted time string (e.g., "1 hour, 2 minutes and 3 seconds")
local function getTimeInWords(secs)
    if type(secs) ~= "number" or secs < 0 then
        return "0 seconds"
    end
    local hours, minutes, seconds = getHours(secs), getMinutes(secs), getSeconds(secs)
    if minutes > 59 then
        minutes = minutes - hours * 60
    end
    local timeStr = ""
    if hours > 0 then
        timeStr = timeStr .. string.format("%d hour%s, ", hours, hours > 1 and "s" or "")
    end
    timeStr = timeStr .. string.format("%d minute%s and %d second%s", minutes, minutes ~= 1 and "s" or "", seconds, seconds ~= 1 and "s" or "")
    return timeStr
end

-- Get default state data for a modal
-- @param player: Player object
-- @param modalState: Modal state ID
-- @return: State data table
local function getDefaultStateData(player, modalState)
    if not isValidPlayer(player) then
        return {}
    end
    local stateData = {}
    if modalState == MODAL_STATE_MAINMENU then
        stateData.playerid = player:getId()
        stateData.title = "Reward Wall"
        local currentDayStreak = player:getCurrentDayStreak()
        local currentLanePlace = player:getCurrentRewardLaneIndex()
        local instantTokenBalance = player:getInstantRewardTokens()
        stateData.message = string.format(
            "--------------- Welcome to your reward wall! ------------------\n\n" ..
            "You're in a %d-day streak\nOn the reward #%d\nInstant Reward Access: %d\n\n" ..
            "Remember that you can always open this window with the \"!daily\" command.\n",
            currentDayStreak, currentLanePlace, instantTokenBalance
        )
    end
    return stateData
end

-- Set modal state for a player
-- @param playerId: Player ID
-- @param state: Modal state table
local function setModalState(playerId, state)
    if playerId and state then
        dailyRewardStates[playerId] = state
    end
end

-- Clear modal state for a player
-- @param playerId: Player ID
local function clearModalState(playerId)
    if playerId then
        dailyRewardStates[playerId] = nil
    end
end

-- Get default choices for the main menu
-- @param player: Player object
-- @return: Choices table
local function getDefaultChoices(player)
    if not isValidPlayer(player) then
        return {ids = {}, names = {}, choicedata = {}}
    end
    return {
        ids = {},
        names = {
            "Resting Area Bonuses (" .. tostring(player:getCurrentDayStreak()) .. ")",
            "Daily Rewards " .. tostring(player:canGetDailyReward() and "[*]" or "[ ]"),
            "Reward History"
        },
        choicedata = {
            {tostate = MODAL_STATE_VIEWSTREAKBONUSES_INDEX},
            {tostate = MODAL_STATE_VIEWDAILYREWARD_LANE},
            {tostate = MODAL_STATE_VIEWREWARDHISTORY}
        }
    }
end

-- Get default button names
-- @return: Button names table
local function getDefaultButtonNames()
    return {"Submit", "Close"}
end

-- Get default enter button name
-- @return: Enter button name
local function getDefaultEnterButtonName()
    return "Submit"
end

-- Get default cancel button name
-- @return: Cancel button name
local function getDefaultCancelButtonName()
    return "Close"
end

-- Get streak status text
-- @param player: Player object
-- @param rewardStreak: Streak reward data
-- @return: Status text
local function getStreakStatusText(player, rewardStreak)
    if not isValidPlayer(player) or not rewardStreak then
        return "locked"
    end
    local isPremium = player:isPremium()
    local currentDayStreak = player:getCurrentDayStreak()
    if rewardStreak.premium and not isPremium then
        return "locked - Premium only"
    elseif currentDayStreak >= rewardStreak.days then
        return "active"
    elseif currentDayStreak == rewardStreak.days - 1 and player:canGetDailyReward() then
        return "GET TODAY'S REWARD TO ACTIVATE"
    else
        return "locked"
    end
end

-- Get available reward items for a player
-- @param pid: Player ID
-- @param forceReload: Force reload of cache
-- @return: Available runes and potions
local function getAvailableRewardItems(pid, forceReload)
    if not isValidPlayer(Player(pid)) then
        return {}
    end
    if not forceReload and itemsCache[pid] then
        return itemsCache[pid]
    end

    local player = Player(pid)
    local reward = {}
    local runes = player:getRuneSpells(true)
    if runes then
        reward.runes = runes
    end

    local potions = {}
    for _, potionId in ipairs(potionsIds) do
        if player:canUsePotion(potionId, true) then
            local itemType = ItemType(potionId)
            table.insert(potions, {
                name = itemType:getArticle() .. " " .. itemType:getName(),
                potionid = potionId,
                spriteid = itemType:getClientId()
            })
        end
    end
    if #potions > 0 then
        reward.potions = potions
    end

    itemsCache[pid] = reward
    return reward
end

-- Get available daily reward items for the player
-- @return: Available runes and potions
function Player:getAvailableDailyRewardItems()
    return getAvailableRewardItems(self:getId())
end

-- Get static modal state
-- @param pid: Player ID
-- @param modalState: Modal state ID
-- @param additional: Additional data (e.g., lane index, streak index)
-- @return: Modal state table
local function getStaticState(pid, modalState, additional)
    if not isValidPlayer(Player(pid)) then
        return {}
    end
    local state = {}
    local player = Player(pid)

    if modalState == MODAL_STATE_VIEWSTREAKBONUSES_INDEX then
        state = {stateId = MODAL_STATE_VIEWSTREAKBONUSES_INDEX}
        local currentDayStreak = player:getCurrentDayStreak()
        local message = string.format(
            "These are your Resting Area Bonuses!\n\nYou're in a %d-day streak%s\n",
            currentDayStreak, currentDayStreak > 2 and "!!" or "."
        )
        if player:canGetDailyReward() then
            local timeLeft = Game.getLastServerSave() + 24 * 60 * 60 - os.time()
            message = message .. string.format(
                "Hurry up! Pick up your daily reward within the next %s " ..
                "(before the next regular server save) to raise your reward streak by one.\n" ..
                "Raise your reward streak to benefit from bonuses in resting areas.",
                getTimeInWords(timeLeft)
            )
        end
        state.statedata = {
            playerid = pid,
            title = "Resting Area Bonuses",
            message = message
        }
        local names = {}
        local choicesData = {}
        for i, streak in ipairs(REWARD_STREAK) do
            names[i] = string.format("%d - %s [%s]", streak.days, streak.description, getStreakStatusText(player, streak))
            choicesData[i] = {tostate = MODAL_STATE_VIEWSTREAKBONUSES_DETAILS, streak_index = i}
        end
        state.choices = {
            ids = {},
            names = names,
            choicedata = choicesData
        }
        state.buttons = {
            names = {"Close", "Back", "Details"},
            defaultEnterName = "Details",
            defaultCancelName = "Close",
            callbacks = {
                function(button, choice) -- Close
                    clearModalState(pid)
                end,
                function(button, choice) -- Back
                    local stateDefault = getDefaultModalState(player)
                    setModalState(pid, stateDefault)
                    sendModalSelectRecursive(player)
                end,
                function(button, choice) -- Details
                    local stateDetails = getStaticState(pid, MODAL_STATE_VIEWSTREAKBONUSES_DETAILS, choice.choicedata.streak_index)
                    setModalState(pid, stateDetails)
                    sendModalSelectRecursive(player)
                end
            }
        }
    elseif modalState == MODAL_STATE_VIEWSTREAKBONUSES_DETAILS then
        local streakIndex = additional
        local rewardStreak = REWARD_STREAK[streakIndex]
        if not rewardStreak then
            return {}
        end
        local message = string.format(
            "%d-Day streak bonus (%s)\n\nThis bonus is active if you reached a reward streak of at least %d.\n\n%s",
            rewardStreak.days, getStreakStatusText(player, rewardStreak), rewardStreak.days, rewardStreak.fullDescription
        )
        state = {stateId = MODAL_STATE_VIEWSTREAKBONUSES_DETAILS}
        state.statedata = {
            playerid = pid,
            title = "Resting Area Bonuses (Details)",
            message = message
        }
        state.buttons = {
            names = {"Back", "Close"},
            defaultEnterName = "Back",
            defaultCancelName = "Close",
            callbacks = {
                function(button, choice) -- Back
                    local stateIndex = getStaticState(pid, MODAL_STATE_VIEWSTREAKBONUSES_INDEX)
                    setModalState(pid, stateIndex)
                    sendModalSelectRecursive(player)
                end,
                function(button, choice) -- Close
                    clearModalState(pid)
                end
            }
        }
    elseif modalState == MODAL_STATE_VIEWDAILYREWARD_LANE then
        state = {stateId = MODAL_STATE_VIEWDAILYREWARD_LANE}
        local laneIndex = additional or player:getCurrentRewardLaneIndex()
        local reward = player:isPremium() and REWARD_LANE.PREMIUM_ACC[laneIndex] or REWARD_LANE.FREE_ACC[laneIndex]
        if not reward then
            return {}
        end
        local message = ""
        if player:canGetDailyReward() then
            message = string.format("Your today's reward is:\n\n- %s.\n\n", reward.description)
            if player:isCloseToRewardShrine() then
                message = message .. "Since you're close to a reward shrine, this reward pickup is FREE!"
            else
                local instantRewardTokens = player:getInstantRewardTokens()
                if instantRewardTokens > 0 then
                    message = message .. string.format(
                        "Caution! You are far from a reward shrine. This reward pickup will use 1 of your %d Instant Reward Access.",
                        instantRewardTokens
                    )
                else
                    message = message .. "Not enough Instant Reward Access points to pick up this reward.\n" ..
                              "You can purchase an Instant Reward Access in the store or visit a reward shrine to pick up your daily reward for FREE."
                    state.buttons = {
                        names = {"Back", "Store", "Close"},
                        defaultEnterName = "Store",
                        defaultCancelName = "Close",
                        callbacks = {
                            function(button, choice) -- Back
                                local stateDetails = getDefaultModalState(player)
                                setModalState(pid, stateDetails)
                                sendModalSelectRecursive(player)
                            end,
                            function(button, choice) -- Open Store
                                clearModalState(pid)
                                player:openStore("Useful Things")
                            end,
                            function(button, choice) -- Close
                                clearModalState(pid)
                            end
                        }
                    }
                    state.statedata = {
                        playerid = pid,
                        title = "Daily Reward",
                        message = message
                    }
                    return state
                end
            end
            local buttons
            if reward.type == REWARD_TYPE_RUNE_POT then
                buttons = {
                    names = {"Back", "Choose", "Close"},
                    defaultEnterName = "Choose",
                    defaultCancelName = "Close",
                    callbacks = {
                        function(button, choice) -- Back
                            local stateDetails = getDefaultModalState(player)
                            setModalState(pid, stateDetails)
                            sendModalSelectRecursive(player)
                        end,
                        function(button, choice) -- Choose items
                            local stateChooseItems = getStaticState(pid, MODAL_STATE_SELECTING_REWARD_ITEMS, reward)
                            setModalState(pid, stateChooseItems)
                            sendModalSelectRecursive(player)
                        end,
                        function(button, choice) -- Close
                            clearModalState(pid)
                        end
                    }
                }
            else
                buttons = {
                    names = {"Back", "Claim", "Close"},
                    defaultEnterName = "Claim",
                    defaultCancelName = "Close",
                    callbacks = {
                        function(button, choice) -- Back
                            local stateDetails = getDefaultModalState(player)
                            setModalState(pid, stateDetails)
                            sendModalSelectRecursive(player)
                        end,
                        function(button, choice) -- Claim
                            local stateConfirm = getStaticState(pid, MODAL_STATE_CONFIRM_REWARD_PICK, reward)
                            setModalState(pid, stateConfirm)
                            sendModalSelectRecursive(player)
                        end,
                        function(button, choice) -- Close
                            clearModalState(pid)
                        end
                    }
                }
            end
            state.buttons = buttons
        else
            local laneIndex = player:getCurrentRewardLaneIndex(false)
            local nextReward = player:isPremium() and REWARD_LANE.PREMIUM_ACC[laneIndex].description or REWARD_LANE.FREE_ACC[laneIndex].description
            local timeLeft = player:getLastRewardClaim() + (24 * 60 * 60) - os.time()
            message = string.format(
                "Congratulations! You've already taken your daily reward.\n\n" ..
                "The next daily reward will be available in %s.\n\n" ..
                "Your next daily reward will be:\n        %s\n",
                getTimeInWords(timeLeft > 0 and timeLeft or 0), nextReward
            )
            state.buttons = {
                names = {"Back", "Close"},
                defaultEnterName = "Back",
                defaultCancelName = "Close",
                callbacks = {
                    function(button, choice) -- Back
                        local stateMainMenu = getDefaultModalState(player)
                        setModalState(pid, stateMainMenu)
                        sendModalSelectRecursive(player)
                    end,
                    function(button, choice) -- Close
                        clearModalState(pid)
                    end
                }
            }
        end
        state.statedata = {
            title = "Daily Reward",
            message = message,
            playerid = pid
        }
    elseif modalState == MODAL_STATE_CONFIRM_REWARD_PICK then
        local reward = additional
        if not reward then
            return {}
        end
        if reward.type == REWARD_TYPE_RUNE_POT then
            local current = dailyRewardStates[pid]
            if current and current.statedata and current.statedata.selection then
                local selectionReward = current.statedata.selection
                local playerSelection = {}
                local totalWeight = 0
                local message = "The following items will be delivered to your store inbox:\n"
                for itemId, count in pairs(selectionReward) do
                    table.insert(playerSelection, {itemid = itemId, count = count})
                    local itemType = ItemType(itemId)
                    totalWeight = totalWeight + itemType:getWeight(count)
                    message = message .. string.format("%dx %s; ", count, itemType:getName())
                end
                message = message .. string.format(
                    "\n\nTotal weight: %.2f oz.\nMake sure you have enough capacity.\nConfirm selection?\n",
                    totalWeight / 100.0
                )
                local useToken = player:isCloseToRewardShrine() and 0 or 1
                if useToken > 0 then
                    message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
                end
                state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}
                state.buttons = {
                    names = {"Cancel", "Confirm"},
                    defaultEnterName = "Confirm",
                    defaultCancelName = "Cancel",
                    callbacks = {
                        function(button, choice) -- Cancel
                            clearModalState(pid)
                        end,
                        function(button, choice) -- Confirm
                            local useToken = player:isCloseToRewardShrine() and 0 or 1
                            player:receiveReward(useToken, reward.type, playerSelection)
                            clearModalState(pid)
                        end
                    }
                }
                state.statedata = {
                    playerid = pid,
                    title = "Reward Selection",
                    message = message
                }
            else
                state = {
                    stateId = MODAL_STATE_CONFIRM_REWARD_PICK,
                    statedata = {
                        playerid = pid,
                        title = "Daily Reward System - Error",
                        message = "Invalid items selection!\n\nTry again with valid items."
                    },
                    buttons = {
                        names = {"Close"},
                        callbacks = {
                            function(button, choice)
                                clearModalState(pid)
                            end
                        },
                        defaultEnterName = "Close",
                        defaultCancelName = "Close"
                    }
                }
            end
        elseif reward.type == REWARD_TYPE_TEMPORARYITEM then
            local items = reward.items
            if not items then
                return {}
            end
            local playerSelection = {}
            local totalWeight = 0
            local message = "The following items will be delivered to your store inbox:\n"
            for _, item in ipairs(items) do
                local itemId, count = item.id, item.ammount
                table.insert(playerSelection, {itemid = itemId, count = count})
                local itemType = ItemType(itemId)
                totalWeight = totalWeight + itemType:getWeight(count)
                message = message .. string.format("%dx %s; ", count, itemType:getName())
            end
            message = message .. string.format(
                "\n\nTotal weight: %.2f oz.\nMake sure you have enough capacity.\nConfirm selection?\n",
                totalWeight / 100.0
            )
            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end
            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}
            state.buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice) -- Confirm
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, playerSelection)
                        clearModalState(pid)
                    end
                }
            }
            state.statedata = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }
        elseif reward.type == REWARD_TYPE_XP_BOOST then
            local message = string.format(
                "You will receive:\n\n%d minutes of XP BOOST will be added to your character\nConfirm selection?\n",
                reward.ammount
            )
            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end
            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}
            state.buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice) -- Confirm
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, reward.ammount)
                        clearModalState(pid)
                    end
                }
            }
            state.statedata = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }
        elseif reward.type == REWARD_TYPE_PREY_REROLL then
            local message = string.format(
                "You will receive:\n\n%d Prey Bonus Reroll%s will be added to your character\nConfirm selection?\n",
                reward.ammount, reward.ammount > 1 and "s" or ""
            )
            local useToken = player:isCloseToRewardShrine() and 0 or 1
            if useToken > 0 then
                message = message .. "\nTHIS WILL USE 1 INSTANT REWARD ACCESS."
            end
            state = {stateId = MODAL_STATE_CONFIRM_REWARD_PICK}
            state.buttons = {
                names = {"Cancel", "Confirm"},
                defaultEnterName = "Confirm",
                defaultCancelName = "Cancel",
                callbacks = {
                    function(button, choice) -- Cancel
                        clearModalState(pid)
                    end,
                    function(button, choice) -- Confirm
                        local useToken = player:isCloseToRewardShrine() and 0 or 1
                        player:receiveReward(useToken, reward.type, reward.ammount)
                        clearModalState(pid)
                    end
                }
            }
            state.statedata = {
                playerid = pid,
                title = "Pick Reward",
                message = message
            }
        end
    elseif modalState == MODAL_STATE_SELECTING_REWARD_ITEMS then
        if not itemsCache[pid] then
            itemsCache[pid] = getAvailableRewardItems(pid)
        end
        local reward = additional
        if not reward then
            return {}
        end
        state = getChoiceModalState(pid, reward)
    elseif modalState == MODAL_STATE_VIEWREWARDHISTORY_DETAILS then
        local history = additional
        if not history then
            return {}
        end
        state = {stateId = MODAL_STATE_VIEWREWARDHISTORY_DETAILS}
        state.buttons = {
            names = {"Back", "Close"},
            defaultEnterName = "Back",
            defaultCancelName = "Close",
            callbacks = {
                function(button, choice) -- Back
                    local stateDefault = getDefaultModalState(player)
                    setModalState(pid, stateDefault)
                    sendModalSelectRecursive(player)
                end,
                function(button, choice) -- Close
                    clearModalState(pid)
                end
            }
        }
        local pickCost = history.instantCost > 0 and
            string.format("This reward pick used %d Instant Reward Access.", history.instantCost) or
            "This reward pick was FREE."
        local message = string.format(
            "History Details\n\nDate: %s\nStreak: %d\nEvent: %s\n\n%s",
            os.date("%Y-%m-%d %X", history.timestamp), history.streak, history.event, pickCost
        )
        state.statedata = {
            playerid = pid,
            title = "Reward Wall - History Details",
            message = message
        }
    end
    return state
end

-- Get modal state for selecting reward items
-- @param pid: Player ID
-- @param reward: Reward data
-- @return: Modal state table
function getChoiceModalState(pid, reward)
    local player = Player(pid)
    if not isValidPlayer(player) or not reward then
        return {}
    end
    local state = {stateId = MODAL_STATE_SELECTING_REWARD_ITEMS}
    local potionsSelectable = itemsCache[pid].potions or {}
    local runesSelectable = itemsCache[pid].runes or {}
    local choices = dailyRewardStates[pid] and dailyRewardStates[pid].choices or {ids = {}}
    if not choices.names then
        local choicesNames = {}
        local choicesData = {}
        local i = 1
        for _, potion in ipairs(potionsSelectable) do
            choicesNames[i] = potion.name
            choicesData[i] = potion.potionid
            i = i + 1
        end
        for _, rune in ipairs(runesSelectable) do
            local itemType = ItemType(rune.runeid)
            choicesNames[i] = itemType:getArticle() .. " " .. itemType:getName()
            choicesData[i] = rune.runeid
            i = i + 1
        end
        choices.names = choicesNames
        choices.choicedata = choicesData
    end
    state.choices = choices
    local currentSelection = dailyRewardStates[pid] and dailyRewardStates[pid].statedata and dailyRewardStates[pid].statedata.selection or nil
    local selectionText
    local selectedItemsCount = 0
    local totalWeight = 0
    if currentSelection then
        selectionText = "\nCurrently selected:\n"
        for itemId, quantity in pairs(currentSelection) do
            local itemType = ItemType(itemId)
            totalWeight = totalWeight + itemType:getWeight(quantity)
            selectedItemsCount = selectedItemsCount + quantity
            selectionText = selectionText .. string.format("%dx %s; ", quantity, itemType:getName())
        end
        selectionText = selectionText .. "\n"
    end
    local message = string.format("You have selected %d of %d reward items.\n", selectedItemsCount, reward.ammount)
    if selectionText then
        message = message .. selectionText
    end
    message = message .. string.format(
        "\nFree Capacity: %.2f oz.\nTotal weight: %.2f oz",
        player:getFreeCapacity() / 100.0, totalWeight / 100.0
    )
    state.statedata = {
        playerid = pid,
        title = "Pick Reward",
        message = message
    }
    if currentSelection then
        state.statedata.selection = currentSelection
    end
    local remaining = reward.ammount - selectedItemsCount
    local addFunc = function(button, choice, addAmount, remainingCount)
        local curSelection = dailyRewardStates[pid] and dailyRewardStates[pid].statedata and dailyRewardStates[pid].statedata.selection or {}
        local itemId = choice.choicedata
        curSelection[itemId] = (curSelection[itemId] or 0) + addAmount
        local stateData = dailyRewardStates[pid]
        stateData.statedata.selection = curSelection
        setModalState(pid, stateData)
        stateData = getChoiceModalState(pid, reward)
        setModalState(pid, stateData)
        if remainingCount - addAmount == 0 then
            local stateReceiveReward = getStaticState(pid, MODAL_STATE_CONFIRM_REWARD_PICK, reward)
            setModalState(pid, stateReceiveReward)
        end
    end
    state.buttons = {
        names = {
            "Back",
            "Add",
            string.format("Add %dx", math.ceil(remaining / 2)),
            string.format("Add %dx", remaining)
        },
        defaultEnterName = "Add",
        defaultCancelName = "Back",
        callbacks = {
            function(button, choice) -- Back
                local stateLane = getStaticState(pid, MODAL_STATE_VIEWDAILYREWARD_LANE, player:getCurrentRewardLaneIndex())
                setModalState(pid, stateLane)
                sendModalSelectRecursive(player)
            end,
            function(button, choice) -- Add 1
                addFunc(button, choice, 1, remaining)
                sendModalSelectRecursive(player)
            end,
            function(button, choice) -- Add half of remaining
                addFunc(button, choice, math.ceil(remaining / 2), remaining)
                sendModalSelectRecursive(player)
            end,
            function(button, choice) -- Add remaining
                addFunc(button, choice, remaining, remaining)
                sendModalSelectRecursive(player)
            end
        }
    }
    return state
end

-- Get default callbacks for main menu
-- @param player: Player object
-- @return: Callbacks table
local function getDefaultCallbacks(player)
    if not isValidPlayer(player) then
        return {}
    end
    local playerId = player:getId()
    return {
        function(button, choice) -- Submit
            local selection = choice.choicedata.tostate
            if selection == MODAL_STATE_VIEWDAILYREWARD_LANE then
                local newState = getStaticState(playerId, MODAL_STATE_VIEWDAILYREWARD_LANE, player:getCurrentRewardLaneIndex())
                setModalState(playerId, newState)
                sendModalSelectRecursive(player)
            elseif selection == MODAL_STATE_VIEWSTREAKBONUSES_INDEX then
                local newState = getStaticState(playerId, MODAL_STATE_VIEWSTREAKBONUSES_INDEX)
                setModalState(playerId, newState)
                sendModalSelectRecursive(player)
            elseif selection == MODAL_STATE_VIEWREWARDHISTORY then
                player:getDailyRewardHistory(function(history)
                    local state = {stateId = MODAL_STATE_VIEWREWARDHISTORY}
                    state.buttons = {
                        names = {"Back", "Details", "Close"},
                        defaultEnterName = "Details",
                        defaultCancelName = "Close",
                        callbacks = {
                            function(button, choice) -- Back
                                local stateDefault = getDefaultModalState(player)
                                setModalState(playerId, stateDefault)
                                sendModalSelectRecursive(player)
                            end,
                            function(button, choice) -- Details
                                local stateDetails = getStaticState(playerId, MODAL_STATE_VIEWREWARDHISTORY_DETAILS, choice.choicedata)
                                setModalState(playerId, stateDetails)
                                sendModalSelectRecursive(player)
                            end,
                            function(button, choice) -- Close
                                clearModalState(playerId)
                            end
                        }
                    }
                    local message = "---------------------- Reward History ----------------------"
                    local choices = {}
                    if history and #history > 0 then
                        local names, data = {}, {}
                        for i, entry in ipairs(history) do
                            local dateStr = os.date("%Y-%m-%d %X", entry.timestamp)
                            local choiceName = string.format("%s - strk:%d - %s", dateStr, entry.streak, entry.event)
                            table.insert(names, choiceName)
                            table.insert(data, entry)
                        end
                        choices = {ids = {}, names = names, choicedata = data}
                        state.choices = choices
                    else
                        message = message .. "\n\nNo reward history yet."
                    end
                    state.statedata = {
                        playerid = playerId,
                        title = "Reward Wall - History",
                        message = message
                    }
                    setModalState(playerId, state)
                    sendModalSelectRecursive(player)
                end, 10)
            end
        end,
        function(button, choice) -- Close
            clearModalState(playerId)
        end
    }
end

-- Get default buttons for main menu
-- @param player: Player object
-- @return: Buttons table
local function getDefaultButtons(player)
    if not isValidPlayer(player) then
        return {}
    end
    return {
        names = getDefaultButtonNames(),
        callbacks = getDefaultCallbacks(player),
        defaultEnterName = getDefaultEnterButtonName(),
        defaultCancelName = getDefaultCancelButtonName()
    }
end

-- Get default modal state
-- @param player: Player object
-- @return: Modal state table
function getDefaultModalState(player)
    if not isValidPlayer(player) then
        return {}
    end
    return {
        stateId = MODAL_STATE_MAINMENU,
        choices = getDefaultChoices(player),
        buttons = getDefaultButtons(player),
        statedata = getDefaultStateData(player, MODAL_STATE_MAINMENU)
    }
end

-- Get current modal state for a player
-- @param playerId: Player ID
-- @return: Modal state table
local function getModalState(playerId)
    if not playerId or not isValidPlayer(Player(playerId)) then
        return nil
    end
    return dailyRewardStates[playerId] or getDefaultModalState(Player(playerId))
end

-- Initialize daily reward system for a player
function Player:initDailyRewardSystem()
    if not isValidPlayer(self) then
        return
    end
    local lastRewardClaim = self:getLastRewardClaim()
    local lastServerSave = Game.getLastServerSave()
    local currentTime = os.time()

    if lastRewardClaim > 0 and lastRewardClaim < (lastServerSave - (24 * 60 * 60)) then
        self:setCurrentDayStreak(0)
        self:setCurrentRewardLaneIndex(0)
    end

    self:loadStreakBonuses()
    self:sendAvailableTokens()
    self:sendDailyRewardBasic()
end

-- Get last reward claim timestamp
-- @return: Timestamp or 0
function Player:getLastRewardClaim()
    return math.max(self:getStorageValue(PlayerStorageKeys.dailyReward.lastRewardClaim), 0)
end

-- Set last reward claim timestamp
-- @param timestamp: Timestamp to set
function Player:setLastRewardClaim(timestamp)
    if type(timestamp) == "number" and timestamp >= 0 then
        self:setStorageValue(PlayerStorageKeys.dailyReward.lastRewardClaim, timestamp)
    else
        print("[Warning] Player.setLastRewardClaim: Invalid timestamp: " .. tostring(timestamp))
    end
end

-- Get current day streak
-- @return: Streak days or 0
function Player:getCurrentDayStreak()
    return math.max(self:getStorageValue(PlayerStorageKeys.dailyReward.streakDays), 0)
end

-- Set current day streak
-- @param value: Streak days
function Player:setCurrentDayStreak(value)
    if type(value) == "number" and value >= 0 then
        self:setStorageValue(PlayerStorageKeys.dailyReward.streakDays, value)
    end
end

-- Get current reward lane index
-- @param zerobased: Use zero-based indexing
-- @return: Lane index
function Player:getCurrentRewardLaneIndex(zerobased)
    local rewardIndex = math.max(self:getStorageValue(PlayerStorageKeys.dailyReward.currentIndex), 0)
    if not zerobased then
        rewardIndex = rewardIndex + 1
    end
    return rewardIndex
end

-- Set current reward lane index
-- @param value: Lane index
function Player:setCurrentRewardLaneIndex(value)
    if type(value) == "number" and value >= 0 then
        self:setStorageValue(PlayerStorageKeys.dailyReward.currentIndex, value)
    end
end

-- Increment reward lane index
function Player:incrementCurrentRewardLaneIndex()
    local currentIndex = self:getCurrentRewardLaneIndex(true)
    local laneLength = self:isPremium() and #REWARD_LANE.PREMIUM_ACC or #REWARD_LANE.FREE_ACC
    currentIndex = (currentIndex + 1) % laneLength
    self:setCurrentRewardLaneIndex(currentIndex)
end

-- Add reward tokens
-- @param amount: Number of tokens to add
function Player:addRewardTokens(amount)
    if type(amount) == "number" and amount > 0 then
        local current = self:getInstantRewardTokens()
        self:setInstantRewardTokens(current + amount)
        self:sendAvailableTokens()
    end
end

-- Remove reward tokens
-- @param amount: Number of tokens to remove
function Player:removeRewardTokens(amount)
    if type(amount) == "number" and amount > 0 then
        local current = self:getInstantRewardTokens()
        self:setInstantRewardTokens(math.max(current - amount, 0))
        self:sendAvailableTokens()
    end
end

-- Use one reward token
function Player:useRewardToken()
    self:removeRewardTokens(1)
end

-- Check if player is close to specific items
-- @param itemList: List of item IDs
-- @return: True if close to any item
function Player:isCloseToAnyOfItems(itemList)
    local pos = self:getPosition()
    for x = -1, 1 do
        for y = -1, 1 do
            local tile = Tile(pos.x + x, pos.y + y, pos.z)
            if tile then
                for _, itemId in ipairs(itemList) do
                    if tile:getItemById(itemId) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check if player is close to a reward shrine
-- @return: True if close to a shrine
function Player:isCloseToRewardShrine()
    return self:isCloseToAnyOfItems(rewardShrineIds)
end

-- Enable soul regeneration in rest areas
function Player:enableSoulRegenInRestAreas()
    local soulCondition = Condition(CONDITION_SOULBONUS, CONDITIONID_DEFAULT)
    soulCondition:setTicks((Game.getLastServerSave() + (24 * 60 * 60) - os.time()) * 1000)
    local vocation = self:getVocation()
    if vocation then
        soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
        soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)
        self:addCondition(soulCondition)
    end
end

-- Enable stamina regeneration in rest areas
function Player:enableStaminaRegenInRestAreas()
    local conditionStamina = Condition(CONDITION_STAMINAREGEN, CONDITIONID_DEFAULT)
    conditionStamina:setTicks((Game.getLastServerSave() + (24 * 60 * 60) - os.time()) * 1000)
    conditionStamina:setParameter(CONDITION_PARAM_STAMINAGAIN, 1)
    self:addCondition(conditionStamina)
end

-- Enable streak bonus for a specific day
-- @param day: Streak day
function Player:enableStreakBonus(day)
    if day == 7 then
        self:enableSoulRegenInRestAreas()
    elseif day == 4 then
        self:enableStaminaRegenInRestAreas()
    end
end

-- Load streak bonuses for the player
function Player:loadStreakBonuses()
    local isPremium = self:isPremium()
    local streakDays = math.min(self:getCurrentDayStreak(), isPremium and 7 or 3)
    local function applyBonusRecursive(day)
        if day < 2 then
            return
        end
        self:enableStreakBonus(day)
        applyBonusRecursive(day - 1)
    end
    applyBonusRecursive(streakDays)
end

-- Receive a daily reward
-- @param useToken: Number of tokens to use (0 or 1)
-- @param rewardType: Type of reward
-- @param additional: Additional data (items, amount)
function Player:receiveReward(useToken, rewardType, additional)
    if not isValidPlayer(self) then
        return
    end
    local client = self:getClient()
    if client and ((client.os > 1100 or client.os ~= CLIENTOS_FLASH) and client.version >= 1140) then
        self:sendCloseRewardWall()
    end
    if not self:canGetDailyReward() then
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return self:sendCancelMessage("You can only claim one daily reward per 24 hours. Please wait until the next reward is available.")
    end
    if useToken > 0 and self:getInstantRewardTokens() == 0 then
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return self:sendCancelMessage("Not enough instant reward tokens.")
    end

    local historyExtra = ""
    if rewardType == REWARD_TYPE_RUNE_POT or rewardType == REWARD_TYPE_TEMPORARYITEM then
        local totalWeight = 0
        local selection = additional
        if not selection or type(selection) ~= "table" then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            return self:sendCancelMessage("Invalid reward selection.")
        end
        for _, item in ipairs(selection) do
            totalWeight = totalWeight + ItemType(item.itemid):getWeight(item.count)
        end
        if self:getFreeCapacity() < totalWeight then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            return self:sendCancelMessage(RETURNVALUE_NOTENOUGHCAPACITY)
        end
        local inbox = self:getSlotItem(CONST_SLOT_STORE_INBOX)
        if not inbox or inbox:getEmptySlots() == 0 then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            return self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
        end
        for _, item in ipairs(selection) do
            local itemType = ItemType(item.itemid)
            inbox:addItem(item.itemid, item.count, INDEX_WHEREEVER, FLAG_NOLIMIT)
            historyExtra = historyExtra .. string.format(" %dx %s;", item.count, itemType:getName())
        end
    elseif rewardType == REWARD_TYPE_PREY_REROLL then
        local bonusCount = additional
        if type(bonusCount) == "number" and bonusCount > 0 then
            self:setBonusRerollCount(self:getBonusRerollCount() + bonusCount)
        end
    elseif rewardType == REWARD_TYPE_XP_BOOST then
        local minutes = additional
        if type(minutes) == "number" and minutes > 0 then
            local currentExpBoostTime = self:getExpBoostStamina()
            self:setExpBoostStamina(currentExpBoostTime + minutes * 60)
            self:setStoreXpBoost(50)
            self:sendStats()
        end
    end

    if useToken > 0 then
        self:useRewardToken()
    end

    local historyMsg = string.format("Claimed reward no.%d.", self:getCurrentRewardLaneIndex(false))
    if rewardType == REWARD_TYPE_RUNE_POT or rewardType == REWARD_TYPE_TEMPORARYITEM then
        historyMsg = historyMsg .. " Picked items:" .. historyExtra
    end

    self:setLastRewardClaim(os.time())
    self:incrementCurrentRewardLaneIndex()
    self:setCurrentDayStreak(self:getCurrentDayStreak() + 1)
    if self:getCurrentDayStreak() <= 7 then
        self:enableStreakBonus(self:getCurrentDayStreak())
    end
    self:addDailyRewardHistory(self:getCurrentDayStreak(), historyMsg, useToken)

    if client and ((client.version > 1100 or client.os ~= CLIENTOS_FLASH) and client.version >= 1140) then
        self:sendDailyRewardBasic()
        self:sendNativeRewardWindow()
    end

    local effect = math.random(29, 31)
    self:getPosition():sendMagicEffect(effect)
end

-- Check if player can get a daily reward
-- @return: True if eligible, false otherwise
function Player:canGetDailyReward()
    if not isValidPlayer(self) then
        return false
    end
    local currentTime = os.time()
    local lastRewardClaim = self:getLastRewardClaim()
    local lastServerSave = Game.getLastServerSave()

    if lastRewardClaim > 0 and (currentTime - lastRewardClaim) < (24 * 60 * 60) then
        return false
    end

    if lastRewardClaim > 0 and lastRewardClaim < (lastServerSave - (24 * 60 * 60)) then
        self:setCurrentDayStreak(0)
        self:setCurrentRewardLaneIndex(0)
    end

    return true
end

-- Send modal select window recursively
-- @param player: Player object
function sendModalSelectRecursive(player)
    if not isValidPlayer(player) then
        return
    end
    local playerId = player:getId()
    local state = getModalState(playerId)
    if not state then
        return
    end
    local modal = ModalWindow {
        title = state.statedata.title,
        message = state.statedata.message
    }
    if state.choices then
        for i, name in ipairs(state.choices.names) do
            local choiceId = modal:addChoice(name)
            choiceId.choicedata = state.choices.choicedata[i]
            state.choices.ids[i] = choiceId
        end
    end
    local buttonCount = math.min(4, #state.buttons.names)
    for i = 1, buttonCount do
        modal:addButton(state.buttons.names[i], state.buttons.callbacks[i])
    end
    if state.buttons and state.buttons.defaultEnterName then
        modal:setDefaultEnterButton(state.buttons.defaultEnterName)
    end
    if state.buttons and state.buttons.defaultCancelName then
        modal:setDefaultEscapeButton(state.buttons.defaultCancelName)
    end
    modal:sendToPlayer(player)
end

-- Send reward window based on client version
function Player:sendRewardWindow()
    if not isValidPlayer(self) then
        return
    end
    local client = self:getClient()
    if client and ((client.version <= 1100 and client.os ~= CLIENTOS_FLASH) or client.version < 1140) then
        self:sendModalRewardWindow()
    else
        self:sendNativeRewardWindow()
    end
end

-- Send modal reward window
function Player:sendModalRewardWindow()
    sendModalSelectRecursive(self)
end

-- Send native reward window
function Player:sendNativeRewardWindow()
    if not isValidPlayer(self) then
        return
    end
    local warnUser = self:isCloseToRewardShrine() and 0 or 1
    local warnMessage = warnUser > 0 and
        "Are you sure you want to pick this reward?\n\nTHIS WILL USE 1 INSTANT REWARD ACCESS" or
        "Warning"
    self:sendOpenRewardWall(self:isCloseToRewardShrine() and 1 or 0, self:getLastRewardClaim() + (24 * 60 * 60), warnUser, warnMessage)
end

-- Add daily reward history entry
-- @param currentStreak: Current streak days
-- @param eventText: Event description
-- @param instantCost: Instant reward token cost
function Player:addDailyRewardHistory(currentStreak, eventText, instantCost)
    if not isValidPlayer(self) or type(currentStreak) ~= "number" or type(eventText) ~= "string" then
        return
    end
    local query = string.format(
        "INSERT INTO `daily_reward_history` (`streak`, `event`, `instant`, `player_id`, `time`) " ..
        "VALUES (%d, %s, %d, %d, %d)",
        currentStreak, db.escapeString(eventText), instantCost or 0, self:getGuid(), os.time()
    )
    db.query(query)
end

-- Get daily reward history
-- @param callback: Callback function to receive history
-- @param limit: Maximum number of entries
-- @param page: Page number (optional)
function Player:getDailyRewardHistory(callback, limit, page)
    if not isValidPlayer(self) or type(callback) ~= "function" then
        callback({})
        return
    end
    local sql = string.format(
        "SELECT `streak`, `event`, `time`, `instant` FROM `daily_reward_history` " ..
        "WHERE `player_id` = %d ORDER BY `time` DESC",
        self:getGuid()
    )
    if type(limit) == "number" and limit > 0 then
        sql = sql .. " LIMIT "
        if type(page) == "number" and page >= 0 then
            sql = sql .. string.format("%d, ", page * limit)
        end
        sql = sql .. tostring(limit)
    end
    db.asyncStoreQuery(sql, function(resultId)
        local history = {}
        if resultId then
            repeat
                table.insert(history, {
                    streak = result.getDataInt(resultId, "streak"),
                    event = result.getDataString(resultId, "event"),
                    timestamp = result.getDataInt(resultId, "time"),
                    instantCost = result.getDataInt(resultId, "instant")
                })
            until not result.next(resultId)
            result.free(resultId)
        end
        callback(history)
    end)
end