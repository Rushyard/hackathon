module zinomon::registry {
    use std::vector;
    use sui::tx_context::{Self as tx, TxContext};
    use sui::object;
    use sui::transfer;
    use zinomon::cards;

    /// Error codes
    const EZeroMaxSupply: u64 = 1;
    const EAlreadyExists: u64 = 2;
    const EUnknownCard: u64 = 3;
    const ESupplyExceeded: u64 = 4;
    const ENotAdmin: u64 = 5;
    const EBadRarity: u64 = 6;

    /// Rarity constants
    const RARITY_COMMON: u8 = 0;
    const RARITY_RARE: u8 = 1;
    const RARITY_EPIC: u8 = 2;
    const RARITY_LEGENDARY: u8 = 3;
    const RARITY_COUNT: u8 = 4;

    /// One-time witness required for init.
    public struct REGISTRY has drop {}

    /// Card definition (index = its position in Global.cards).
    public struct CardDefinition has store, copy, drop {
        id: vector<u8>,          // unique textual id
        rarity: u8,              // rarity code
        family: u8,              // merge family id
        supply_cap: u64,         // 0 = unlimited
        total_minted: u64,       // minted so far
        active: bool,            // can be pulled
        metadata_hash: vector<u8>,
        ipfs_cid: vector<u8>,    // pointer to off-chain metadata
    }

    /// Odds entry per rarity for a pack type (scaled by 10_000 for precision).
    public struct Odds has store, copy, drop {
        common_bp: u64,
        rare_bp: u64,
        epic_bp: u64,
        legendary_bp: u64,
    }

    /// Pricing + limits for a pack type.
    public struct PackConfig has store, copy, drop {
        price_mist: u64,        // price in MIST (1 SUI = 1_000_000_000)
        daily_limit: u64,       // per address daily cap
        pity_rare_threshold: u64, // guarantee rare+ after N misses
        pity_epic_threshold: u64, // guarantee epic+ after M misses
    }

    /// Track per-user pack open stats for pity (rolling counters).
    public struct UserPackStats has store, drop {
        address: address,
        consecutive_no_rare: u64,
        consecutive_no_epic: u64,
        last_reset_day: u64,
        opened_free: u64,
        opened_standard: u64,
        opened_premium: u64,
        opened_elite: u64,
    }

    /// Global object for zinomon package.
    public struct Global has key {
        id: object::UID,
        admin: address,
        cards: vector<CardDefinition>,
        /// Pack configs order: 0=Free,1=Standard,2=Premium,3=Elite
        pack_configs: vector<PackConfig>,
        /// Odds aligned with pack configs
        pack_odds: vector<Odds>,
    }

    /// Events
    public struct CardDefined has copy, drop { idx: u64, rarity: u8 }
    public struct CardMinted has copy, drop { def_idx: u64, rarity: u8, owner: address }
    public struct PackOpened has copy, drop { pack_type: u8, rarity: u8, owner: address }

    /// Initialize global (immutable odds & pricing set later by admin calls).
    public fun init(_w: REGISTRY, ctx: &mut TxContext) {
        let admin = tx::sender(ctx);
        let mut pack_configs = vector::empty<PackConfig>();
        // Default placeholder pricing & limits: Free(0), Standard(0.5 SUI), Premium(2 SUI), Elite(10 SUI)
        vector::push_back(&mut pack_configs, PackConfig { price_mist: 0, daily_limit: 1, pity_rare_threshold: 0, pity_epic_threshold: 0 });
        vector::push_back(&mut pack_configs, PackConfig { price_mist: 500_000_000, daily_limit: 2, pity_rare_threshold: 10, pity_epic_threshold: 25 });
        vector::push_back(&mut pack_configs, PackConfig { price_mist: 2_000_000_000, daily_limit: 2, pity_rare_threshold: 10, pity_epic_threshold: 25 });
        vector::push_back(&mut pack_configs, PackConfig { price_mist: 10_000_000_000, daily_limit: 2, pity_rare_threshold: 10, pity_epic_threshold: 25 });
        let mut pack_odds = vector::empty<Odds>();
        // Free odds (basis points out of 10_000): 8200/1600/200/0
        vector::push_back(&mut pack_odds, Odds { common_bp: 8200, rare_bp: 1600, epic_bp: 200, legendary_bp: 0 });
        // Standard: 7000/2700/290/10
        vector::push_back(&mut pack_odds, Odds { common_bp: 7000, rare_bp: 2700, epic_bp: 290, legendary_bp: 10 });
        // Premium: 5500/3500/900/100
        vector::push_back(&mut pack_odds, Odds { common_bp: 5500, rare_bp: 3500, epic_bp: 900, legendary_bp: 100 });
        // Elite: 4000/4000/1850/150
        vector::push_back(&mut pack_odds, Odds { common_bp: 4000, rare_bp: 4000, epic_bp: 1850, legendary_bp: 150 });
        let global = Global { id: object::new(ctx), admin, cards: vector::empty<CardDefinition>(), pack_configs, pack_odds };
        transfer::share_object(global);
    }

    /// Admin check.
    fun assert_admin(global: &Global, sender: address) { assert!(sender == global.admin, ENotAdmin); }

    /// Add a new card definition.
    public fun add_card(
        global: &mut Global,
        id: vector<u8>,
        rarity: u8,
        family: u8,
        supply_cap: u64,
        metadata_hash: vector<u8>,
        ipfs_cid: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(rarity < RARITY_COUNT, EBadRarity);
        let (exists, _) = find_card(&global.cards, &id);
        assert!(!exists, EAlreadyExists);
        let def = CardDefinition { id, rarity, family, supply_cap, total_minted: 0, active: true, metadata_hash, ipfs_cid };
        let idx = vector::length(&global.cards);
        vector::push_back(&mut global.cards, def);
        sui::event::emit(CardDefined { idx, rarity });
    }

    /// Mint a card for definition index to receiver (used by pack logic).
    public fun mint_to(
        global: &mut Global,
        def_idx: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let len = vector::length(&global.cards);
        assert!(def_idx < len, EUnknownCard);
        let def_ref = &mut *vector::borrow_mut(&mut global.cards, def_idx);
        if (def_ref.supply_cap > 0) { assert!(def_ref.total_minted < def_ref.supply_cap, ESupplyExceeded); }
        def_ref.total_minted = def_ref.total_minted + 1;
        let serial = def_ref.total_minted;
        let rarity = def_ref.rarity;
        let family = def_ref.family;
        let card = cards::mint_card_internal(rarity, family, serial, def_ref.metadata_hash.clone(), ctx);
        transfer::public_transfer(card, receiver);
        sui::event::emit(CardMinted { def_idx, rarity, owner: receiver });
    }

    /// Internal helper to find index of card id; returns (bool, idx)
    fun find_card(cards: &vector<CardDefinition>, id: &vector<u8>): (bool, u64) {
        let len = vector::length(cards);
        let mut i = 0; while (i < len) { let cid_ref = &vector::borrow(cards, i).id; if (*cid_ref == *id) { return (true, i); }; i = i + 1; }; (false, 0)
    }

    /// Get definition count
    public fun card_count(global: &Global): u64 { vector::length(&global.cards) }

    /// Borrow definition
    public fun borrow_card(global: &Global, id: &vector<u8>): &CardDefinition { let (e,i)=find_card(&global.cards,id); assert!(e,EUnknownCard); vector::borrow(&global.cards,i) }
}
