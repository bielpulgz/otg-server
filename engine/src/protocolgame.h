/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019 Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef FS_PROTOCOLGAME_H_FACA2A2D1A9348B78E8FD7E8003EBB87
#define FS_PROTOCOLGAME_H_FACA2A2D1A9348B78E8FD7E8003EBB87

#include "protocol.h"
#include "chat.h"
#include "creature.h"
#include "tasks.h"
#include "protocolgamebase.h"
#include "protocolspectator.h"

class NetworkMessage;
class Player;
class Game;
class House;
class Container;
class Tile;
class Connection;
class Quest;
class ProtocolGame;
class ProtocolSpectator;
using ProtocolGame_ptr = std::shared_ptr<ProtocolGame>;

extern Game g_game;

struct LootBlock;

struct TextMessage
{
	MessageClasses type = MESSAGE_STATUS_DEFAULT;
	std::string text;
	Position position;
	uint16_t channelId;
	struct {
		int32_t value = 0;
		TextColor_t color;
	} primary, secondary;

	TextMessage() = default;
	TextMessage(MessageClasses type, std::string text) : type(type), text(std::move(text)) {}
};

class ProtocolGame final : public ProtocolGameBase
{
	public:
		static const char* protocol_name() {
			return "gameworld protocol";
		}

		explicit ProtocolGame(Connection_ptr connection) : ProtocolGameBase(connection) {}

		void login(const std::string& name, uint32_t accnumber, OperatingSystem_t operatingSystem);
		void logout(bool displayEffect, bool forced);

		void AddItem(NetworkMessage& msg, const Item* item);
		void AddItem(NetworkMessage& msg, uint16_t id, uint8_t count);

		uint16_t getVersion() const {
			return version;
		}

		const std::unordered_set<uint32_t>& getKnownCreatures() const {
			return knownCreatureSet;
		}

		typedef std::unordered_map<Player*, ProtocolGame_ptr> LiveCastsMap;
		typedef std::vector<ProtocolSpectator_ptr> CastSpectatorVec;

		/** \brief Adds a spectator from the spectators vector.
		 *  \param spectatorClient pointer to the \ref ProtocolSpectator object representing the spectator
		 */
		void addSpectator(ProtocolSpectator_ptr spectatorClient);

		/** \brief Removes a spectator from the spectators vector.
		 *  \param spectatorClient pointer to the \ref ProtocolSpectator object representing the spectator
		 */
		void removeSpectator(ProtocolSpectator_ptr spectatorClient);

		/** \brief Starts the live cast.
		 *  \param password live cast password(optional)
		 *  \returns bool type indicating whether starting the cast was successful
		*/
		bool startLiveCast(const std::string& password = "");

		/** \brief Stops the live cast and disconnects all spectators.
		 *  \returns bool type indicating whether stopping the cast was successful
		*/
		bool stopLiveCast();

		const CastSpectatorVec& getLiveCastSpectators() const {
			return spectators;
		}

		size_t getSpectatorCount() const {
			return spectators.size();
		}

		bool isLiveCaster() const {
			return isCaster.load(std::memory_order_relaxed);
		}

		std::mutex liveCastLock;

		/** \brief Adds a new live cast to the list of available casts
		 */
		void registerLiveCast();

		/** \brief Removes a live cast from the list of available casts
		 */
		void unregisterLiveCast();

		/** \brief Update live cast info in the database.
		 *  \param player pointer to the casting \ref Player object
		 *  \param client pointer to the caster's \ref ProtocolGame object
		 */
		void updateLiveCastInfo();

		/** \brief Clears all live casts. Used to make sure there aro no live cast db rows left should a crash occur.
		 *  \warning Only supposed to be called once.
		 */
		static void clearLiveCastInfo();

		/** \brief Finds the caster's \ref ProtocolGame object
		 *  \param player pointer to the casting \ref Player object
		 *  \returns A pointer to the \ref ProtocolGame of the caster
		 */
		static ProtocolGame_ptr getLiveCast(Player* player) {
			const auto it = liveCasts.find(player);
			return it != liveCasts.end() ? it->second : nullptr;
		}

		const std::string& getLiveCastName() const {
			return liveCastName;
		}

		const std::string& getLiveCastPassword() const {
			return liveCastPassword;
		}

		bool isPasswordProtected() const {
			return !liveCastPassword.empty();
		}
		void incrementeLiveCastViews() {
			liveCastViews++;
		}

		int8_t getLiveCastViews() {
			return liveCastViews;
		}
		static const LiveCastsMap& getLiveCasts() {
			return liveCasts;
		}

		/** \brief Allows spectators to send text messages to the caster
		 *   and then get broadcast to the rest of the spectators
		 *  \param text string containing the text message
		 */
		void broadcastSpectatorMessage(const std::string& text) {
			if (player) {
				sendChannelMessage("Spectator", text, TALKTYPE_CHANNEL_Y, CHANNEL_CAST);
			}
		}
		void sendSpectatorMessage(const std::string& name, const std::string& text) {
			if (player) {
				sendChannelMessage(name, text, TALKTYPE_CHANNEL_Y, CHANNEL_CAST);
			}
		}

		static uint8_t getMaxLiveCastCount() {
			return std::numeric_limits<int8_t>::max();
		}
	private:
		ProtocolGame_ptr getThis() {
			return std::static_pointer_cast<ProtocolGame>(shared_from_this());
		}
		void connect(uint32_t playerId, OperatingSystem_t operatingSystem);
		void disconnectClient(const std::string& message) const;
		void writeToOutputBuffer(const NetworkMessage& msg, bool broadcast = true) final;

		void release() final;

		// we have all the parse methods
		void parsePacket(NetworkMessage& msg) final;
		void onRecvFirstMessage(NetworkMessage& msg) final;

		//Parse methods
		void parseAutoWalk(NetworkMessage& msg);
		void parseSetOutfit(NetworkMessage& msg);
		void parseSay(NetworkMessage& msg);
		void parseLookAt(NetworkMessage& msg);
		void parseLookInBattleList(NetworkMessage& msg);
		void parseFightModes(NetworkMessage& msg);
		void parseAttack(NetworkMessage& msg);
		void parseFollow(NetworkMessage& msg);
		void parseEquipObject(NetworkMessage& msg);

		void parseResquestLockItems();

		void parseQuickLoot(NetworkMessage& msg);
		void parseLootContainer(NetworkMessage& msg);
		void parseQuickLootBlackWhitelist(NetworkMessage& msg);

		void parseBugReport(NetworkMessage& msg);
		void parseThankYou(NetworkMessage& msg);
		void parseDebugAssert(NetworkMessage& msg);
		void parseRuleViolationReport(NetworkMessage &msg);

		void parseThrow(NetworkMessage& msg);
		void parseUseItemEx(NetworkMessage& msg);
		void parseUseWithCreature(NetworkMessage& msg);
		void parseUseItem(NetworkMessage& msg);
		void parseCloseContainer(NetworkMessage& msg);
		void parseUpArrowContainer(NetworkMessage& msg);
		void parseUpdateContainer(NetworkMessage& msg);
		void parseTextWindow(NetworkMessage& msg);
		void parseHouseWindow(NetworkMessage& msg);

		void parseLookInShop(NetworkMessage& msg);
		void parsePlayerPurchase(NetworkMessage& msg);
		void parsePlayerSale(NetworkMessage& msg);

		void parseQuestLine(NetworkMessage& msg);

		void parseInviteToParty(NetworkMessage& msg);
		void parseJoinParty(NetworkMessage& msg);
		void parseRevokePartyInvite(NetworkMessage& msg);
		void parsePassPartyLeadership(NetworkMessage& msg);
		void parseEnableSharedPartyExperience(NetworkMessage& msg);

		void parseToggleMount(NetworkMessage& msg);

		// Imbuements
		void parseApplyImbuemente(NetworkMessage& msg);
		void parseClearingImbuement(NetworkMessage& msg);
		void parseCloseImbuingWindow(NetworkMessage& msg);

		void parseModalWindowAnswer(NetworkMessage& msg);

		// Store
		void parseOpenStore();
		void parseRequestStoreOffers(NetworkMessage& msg);
		void parseBuyStoreOffer(NetworkMessage& msg);
		void parseSendDescription(NetworkMessage& msg);
		void parseOpenTransactionHistory(NetworkMessage& msg);
		void parseRequestTransactionHistory(NetworkMessage& msg);
		void requestPurchaseData(uint32_t offerId, uint8_t offerType);

		void sendStoreHistory(uint32_t totalPages, uint32_t pages, std::vector<StoreHistory> filter);

		//Prey system
		void parseRequestResourceData(NetworkMessage& msg);
		void parsePreyAction(NetworkMessage& msg);

		void parseBrowseField(NetworkMessage& msg);
		void parseSeekInContainer(NetworkMessage& msg);

		void parseRequestItemDetail(NetworkMessage& msg);

		//trade methods
		void parseRequestTrade(NetworkMessage& msg);
		void parseLookInTrade(NetworkMessage& msg);

		//market methods
		void parseMarketLeave();
		void parseMarketBrowse(NetworkMessage& msg);
		void parseMarketCreateOffer(NetworkMessage& msg);
		void parseMarketCancelOffer(NetworkMessage& msg);
		void parseMarketAcceptOffer(NetworkMessage& msg);

		//store methods
		void parseTransferCoins(NetworkMessage& msg);

		//VIP methods
		void parseAddVip(NetworkMessage& msg);
		void parseRemoveVip(NetworkMessage& msg);
		void parseEditVip(NetworkMessage& msg);

		void parseRequestBestiaryData();
		void parseRequestBestiaryOverview(NetworkMessage& msg);
		void parseRequestBestiaryMonsterData(NetworkMessage& msg);

		// charm
		void parseRequestCharmData();
		void parseRequestUnlockCharm(NetworkMessage& msg);

		void parseNPCSay(NetworkMessage& msg);

		void parseRotateItem(NetworkMessage& msg);
		void parseWrapableItem(NetworkMessage& msg);

		//Channel tabs
		void parseChannelInvite(NetworkMessage& msg);
		void parseChannelExclude(NetworkMessage& msg);
		void parseOpenChannel(NetworkMessage& msg);
		void parseOpenPrivateChannel(NetworkMessage& msg);
		void parseCloseChannel(NetworkMessage& msg);

		// imbue info
		void addImbuementInfo(NetworkMessage &msg, uint32_t imbuid);

		//Send functions
		void sendChannelMessage(const std::string& author, const std::string& text, SpeakClasses type, uint16_t channel);
		void sendChannelEvent(uint16_t channelId, const std::string& playerName, ChannelEvent_t channelEvent);
		void sendClosePrivate(uint16_t channelId);
		void sendCreatePrivateChannel(uint16_t channelId, const std::string& channelName);
		void sendChannelsDialog();
		void sendOpenPrivateChannel(const std::string& receiver);
		void sendToChannel(const Creature* creature, SpeakClasses type, const std::string& text, uint16_t channelId);
		void sendPrivateMessage(const Player* speaker, SpeakClasses type, const std::string& text);
		void sendRestingAreaIcon(bool activate=false, bool activeResting=false);
		void sendIcons(uint16_t icons);
		void sendFYIBox(const std::string& message);

		void sendImbuementWindow(Item* item);

		void sendBestiaryGroups();
		void sendBestiaryOverview(std::string raceName);
		void sendBestiaryOverview(std::vector<uint16_t> monsters);
		void sendBestiaryMonsterData(uint16_t id);

		// charm
		void sendCharmData();

		void sendDistanceShoot(const Position& from, const Position& to, uint8_t type);
		void sendCreatureHealth(const Creature* creature);
		void sendPlayerMana(const Player* target);
		void sendBestiaryTracker();
		void sendCreatureTurn(const Creature* creature, uint32_t stackpos);
		void sendCreatureSay(const Creature* creature, SpeakClasses type, const std::string& text, const Position* pos = nullptr);

		// Unjust Panel
		void sendUnjustifiedPoints(const uint8_t& dayProgress, const uint8_t& dayLeft, const uint8_t& weekProgress, const uint8_t& weekLeft, const uint8_t& monthProgress, const uint8_t& monthLeft, const uint8_t& skullDuration);

		void sendQuestLog();
		void sendQuestTracker();
		void sendQuestLine(const Quest* quest);

		void sendChangeSpeed(const Creature* creature, uint32_t speed);
		void sendCancelTarget();
		void sendCreatureOutfit(const Creature* creature, const Outfit_t& outfit);
		void sendTextMessage(const TextMessage& message);
		void sendReLoginWindow(uint8_t unfairFightReduction);

		void sendTutorial(uint8_t tutorialId);
		void sendAddMarker(const Position& pos, uint8_t markType, const std::string& desc);
		void sendMapManage(uint8_t action);

		void sendCreatureWalkthrough(const Creature* creature, bool walkthrough);
		void sendCreatureShield(const Creature* creature);
		void sendCreatureSkull(const Creature* creature);
		void sendCreatureType(const Creature* creature, uint8_t creatureType);
		void sendCreatureHelpers(uint32_t creatureId, uint16_t helpers);

		void sendShop(Npc* npc, const ShopInfoList& itemList);
		void sendCloseShop();
		void sendClientCheck();
		void sendGameNews();
		void sendResourceBalance(uint64_t money, uint64_t bank);
		void sendSaleItemList(const std::list<ShopInfo>& shop);
		void sendMarketEnter(uint32_t depotId);
		void sendMarketLeave();
		void sendMarketBrowseItem(uint16_t itemId, const MarketOfferList& buyOffers, const MarketOfferList& sellOffers);
		void sendMarketAcceptOffer(const MarketOfferEx& offer);
		void sendMarketBrowseOwnOffers(const MarketOfferList& buyOffers, const MarketOfferList& sellOffers);
		void sendMarketCancelOffer(const MarketOfferEx& offer);
		void sendMarketBrowseOwnHistory(const HistoryMarketOfferList& buyOffers, const HistoryMarketOfferList& sellOffers);
		void sendMarketDetail(uint16_t itemId);
		void sendItemDetail(uint16_t itemCID);
		void sendTradeItemRequest(const std::string& traderName, const Item* item, bool ack);
		void sendCloseTrade();

		void sendLockerItems(std::map<uint16_t, uint16_t> itemMap, uint16_t count);

		void updateCoinBalance();
		void sendCoinBalance();

		void sendTextWindow(uint32_t windowTextId, Item* item, uint16_t maxlen, bool canWrite);
		void sendTextWindow(uint32_t windowTextId, uint32_t itemId, const std::string& text);
		void sendHouseWindow(uint32_t windowTextId, const std::string& text);
		void sendOutfitWindow();

		void sendUpdatedVIPStatus(uint32_t guid, VipStatus_t newStatus);

		void sendFightModes();

		void sendCreatureSquare(const Creature* creature, SquareColor_t color, uint8_t length);

		void sendSpellCooldown(uint8_t spellId, uint32_t time);
		void sendSpellGroupCooldown(SpellGroup_t groupId, uint32_t time);

		//tiles
		void sendAddTileItem(const Position& pos, uint32_t stackpos, const Item* item);
		void sendUpdateTileItem(const Position& pos, uint32_t stackpos, const Item* item);
		void sendRemoveTileThing(const Position& pos, uint32_t stackpos);

		void sendMoveCreature(const Creature* creature, const Position& newPos, int32_t newStackPos,
							  const Position& oldPos, int32_t oldStackPos, bool teleport);

		//containers
		void sendAddContainerItem(uint8_t cid, uint16_t slot, const Item* item);
		void sendUpdateContainerItem(uint8_t cid, uint16_t slot, const Item* item);
		void sendRemoveContainerItem(uint8_t cid, uint16_t slot, const Item* lastItem);

		void sendCloseContainer(uint8_t cid);

		void sendUpdatePartyInfo(uint32_t playerid, uint8_t info);

		//messages
		void sendModalWindow(const ModalWindow& modalWindow);

		//Prey System
		void sendResourceData(ResourceType_t resourceType, int64_t amount);

		//Help functions

		void MoveUpCreature(NetworkMessage& msg, const Creature* creature, const Position& newPos, const Position& oldPos);
		void MoveDownCreature(NetworkMessage& msg, const Creature* creature, const Position& newPos, const Position& oldPos);

		//shop
		void AddShopItem(NetworkMessage& msg, const ShopInfo& item);

		//otclient
		void parseExtendedOpcode(NetworkMessage& msg);
		
		//OTCv8
		void sendFeatures();

		void parseBestiaryTracker(NetworkMessage& msg);

		friend class Player;
		friend class ProtocolGameBase;
		
		uint16_t otclientV8 = 0;

		// Helpers so we don't need to bind every time
		template <typename Callable, typename... Args>
		void addGameTask(Callable function, Args&&... args) {
			g_dispatcher.addTask(createTask(std::bind(function, &g_game, std::forward<Args>(args)...)));
		}

		template <typename Callable, typename... Args>
		void addGameTaskTimed(uint32_t delay, Callable function, Args&&... args) {
			g_dispatcher.addTask(createTask(delay, std::bind(function, &g_game, std::forward<Args>(args)...)));
		}

		static LiveCastsMap liveCasts; ///< Stores all available casts.

		std::atomic<bool> isCaster {false}; ///< Determines if this \ref ProtocolGame object is casting

		/// list of spectators \warning This variable should only be accessed after locking \ref liveCastLock
		CastSpectatorVec spectators;

		/// Live cast name that is also used as login
		std::string liveCastName;

		/// Password used to access the live cast
		std::string liveCastPassword;

		int8_t liveCastViews = 0;

		void sendInventory();
		
};

#endif