module zinomon::packs_logic {
    use std::vector;
    use sui::tx_context::{Self as tx, TxContext};
    use sui::random; // pseudo randomness
    use zinomon::registry::{Self as reg, Global};

    /// Select a rarity based on odds (basis points) and 64-bit random.
    fun pick_rarity(odds: &reg::Odds, r: u64): u8 {
        let bucket = (r % 10_000);
        let c = odds.common_bp;
        let rc = c + odds.rare_bp;
        let ec = rc + odds.epic_bp;
        if (bucket < c) { 0 } else if (bucket < rc) { 1 } else if (bucket < ec) { 2 } else { 3 }
    }

    /// Find first active card definition of given rarity (placeholder: first match).
    fun pick_definition(global: &Global, rarity: u8): u64 {
        let len = std::vector::length(&global.cards);
        let mut i = 0; while (i < len) { let def = std::vector::borrow(&global.cards, i); if (def.rarity == rarity && def.active) { return i; }; i = i + 1; }; 0
    }

    /// Open a pack (pack_type index) and mint one card to sender.
    public fun open_pack(global: &mut Global, pack_type: u8, ctx: &mut TxContext) {
        let sender = tx::sender(ctx);
        let odds = std::vector::borrow(&global.pack_odds, pack_type as u64);
        let rand_bytes = random::u64(ctx);
        let rarity = pick_rarity(odds, rand_bytes);
        let def_idx = pick_definition(global, rarity);
        reg::mint_to(global, def_idx, sender, ctx);
        // Future: emit PackOpened event after mint (event defined in registry)
    }
}
