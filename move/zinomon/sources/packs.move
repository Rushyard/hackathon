module zinomon::packs {
    public struct Pack has key {
        id: sui::object::UID,
        pack_type: u8,
        cards: vector<sui::object::ID>,
    }

    public fun mint_pack(pack_type: u8, card_ids: vector<sui::object::ID>, ctx: &mut sui::tx_context::TxContext) {
        let pack = Pack { id: sui::object::new(ctx), pack_type, cards: card_ids };
        sui::transfer::share_object(pack);
    }

    public fun open_pack(pack: &mut Pack, _ctx: &mut sui::tx_context::TxContext): vector<sui::object::ID> {
        let cards = pack.cards;
        pack.cards = std::vector::empty<sui::object::ID>();
        cards
    }
}
