module zinomon::cards {
    // Fully qualified references; no unused imports.

    public struct Card has key {
        id: sui::object::UID,
        rarity: u8,
        serial: u64,
        metadata_hash: vector<u8>,
    }

    public fun mint_card(
        rarity: u8,
        serial: u64,
        metadata_hash: vector<u8>,
        ctx: &mut sui::tx_context::TxContext
    ) {
        let card = Card { id: sui::object::new(ctx), rarity, serial, metadata_hash };
        sui::transfer::share_object(card);
    }
}
