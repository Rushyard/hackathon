module zinomon::cards {
    // Fully qualified references; no unused imports.

    public struct Card has key {
        id: sui::object::UID,
        rarity: u8,          // 0=Common,1=Rare,2=Epic,3=Legendary
        family: u8,          // family group id (0-255)
        serial: u64,
        metadata_hash: vector<u8>,
    }

    /// Internal mint (called by registry/packs). Shared so players can hold cards.
    public fun mint_card_internal(
        rarity: u8,
        family: u8,
        serial: u64,
        metadata_hash: vector<u8>,
        ctx: &mut sui::tx_context::TxContext
    ): Card {
        Card { id: sui::object::new(ctx), rarity, family, serial, metadata_hash }
    }

    /// Legacy external mint (for testing) now uses family=0.
    public fun mint_card(
        rarity: u8,
        serial: u64,
        metadata_hash: vector<u8>,
        ctx: &mut sui::tx_context::TxContext
    ) {
        let card = mint_card_internal(rarity, 0, serial, metadata_hash, ctx);
        sui::transfer::share_object(card);
    }
}
