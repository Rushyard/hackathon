module zinomon::registry {
    /// Error codes
    const EZeroMaxSupply: u64 = 1;
    const EAlreadyExists: u64 = 2;
    const EUnknownCard: u64 = 3;

    /// One-time witness required for init.
    public struct REGISTRY has drop {}

    /// Global object for the zinomon package.
    public struct Global has key {
        id: sui::object::UID,
        treasury: address,
        cards: vector<CardDefinition>,
    }

    /// Card definition.
    public struct CardDefinition has store, copy, drop {
        id: vector<u8>,
        rarity: u8,
        max_supply: u64,
        minted: u64,
        metadata_hash: vector<u8>,
    }

    /// Initialize the global object (shared). Only callable once with the REGISTRY witness.
    public fun init(_w: REGISTRY, ctx: &mut sui::tx_context::TxContext) {
        let sender = sui::tx_context::sender(ctx);
        let global = Global { id: sui::object::new(ctx), treasury: sender, cards: std::vector::empty<CardDefinition>() };
        sui::transfer::share_object(global);
    }

    /// Internal helper to find index of a card id; returns (bool, idx)
    fun find_card_internal(cards: &vector<CardDefinition>, id: &vector<u8>, idx: u64): (bool, u64) {
        let len = std::vector::length(cards);
        if (idx >= len) { (false, 0) } else {
            let def = std::vector::borrow(cards, idx);
            if (def.id == *id) { (true, idx) } else { find_card_internal(cards, id, idx + 1) }
        }
    }

    /// Internal helper to find index of a card id; returns (bool, idx)
    fun find_card(cards: &vector<CardDefinition>, id: &vector<u8>): (bool, u64) {
        find_card_internal(cards, id, 0)
    }

    /// Register a new card definition.
    public fun add_card(
        global: &mut Global,
        id: vector<u8>,
        rarity: u8,
        max_supply: u64,
        metadata_hash: vector<u8>
    ) {
        assert!(max_supply > 0, EZeroMaxSupply);
        let (exists, _) = find_card(&global.cards, &id);
        assert!(!exists, EAlreadyExists);
        let card = CardDefinition { id, rarity, max_supply, minted: 0, metadata_hash };
        std::vector::push_back(&mut global.cards, card);
    }

    /// Get total registered card definitions.
    public fun card_count(global: &Global): u64 { std::vector::length(&global.cards) }

    /// Borrow a card definition by id.
    public fun borrow_card(global: &Global, id: &vector<u8>): &CardDefinition {
        let (exists, idx) = find_card(&global.cards, id);
        assert!(exists, EUnknownCard);
        std::vector::borrow(&global.cards, idx)
    }
}
