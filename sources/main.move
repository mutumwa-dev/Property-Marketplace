module Marketplace::main {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext, sender};
    use std::option::{Self, Option, none};
    use std::string::{String};

    // Errors
    const ENotEnough: u64 = 0;
    const ERetailerPending: u64 = 1;
    const ENotOwner: u64 = 2;

    // Struct definitions
    struct PropertyListing has key, store {
        id: UID,
        owner: address,
        buyer: Option<address>,
        description: String,
        price: u64,
        escrow: Balance<SUI>,
        propertySubmitted: bool,
        dispute: bool,
        sellerRating: Option<u8>, // New field to store seller rating
        buyerRating: Option<u8>,  // New field to store buyer rating
    }

    struct PropertyCap has key {
        id: UID,
        to: ID
    }

     // === Public-Mutative Functions ===

    public fun get_price(_: &PropertyCap, self: &PropertyListing): u64 {
        self.price
    }

    public fun get_dispute(self: &PropertyListing): bool {
        self.dispute
    }

    // Public - Entry functions
    public fun new(description: String, price: u64, ctx: &mut TxContext) : PropertyCap {
        
        let listing_id = object::new(ctx);
        let inner_ = object::uid_to_inner(&listing_id);
        transfer::share_object(PropertyListing {
            id: listing_id,
            owner: tx_context::sender(ctx),
            buyer: none(),
            description: description,
            price: price,
            escrow: balance::zero(),
            propertySubmitted: false,
            dispute: false,
            sellerRating: none(), // Initialize to None
            buyerRating: none(),  // Initialize to None
        });

        let cap = PropertyCap{
            id: object::new(ctx),
            to: inner_
        };
        cap
    }

    public fun new_price(cap: &PropertyCap, self: &mut PropertyListing, price: u64) {
        assert!(cap.to == object::id(self), ENotOwner);
        assert!(self.propertySubmitted, ERetailerPending);
        self.price = price;
    }

    public fun deposit(self: &mut PropertyListing, coin: Coin<SUI>) {
        assert!(coin::value(&coin) == self.price, ENotEnough);

        let balance_ = coin::into_balance(coin);
        balance::join(&mut self.escrow, balance_);
    }

     public fun dispute(cap: &PropertyCap, self: &mut PropertyListing) {
        assert!(cap.to == object::id(self), ENotOwner);
        self.dispute = true;
    }

    public fun fill_buyer(self: &mut PropertyListing, ctx: &mut TxContext) {
        option::fill(&mut self.buyer, sender(ctx));
    }

    public fun claim(cap: PropertyCap, self: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(cap.to == object::id(self), ENotOwner);

        // Transfer the balance
        let amount = balance::value(&self.escrow);
        let refund = coin::take(&mut self.escrow, amount, ctx);
        transfer::public_transfer(refund, sender(ctx));
        // Transfer the ownership
        transfer::transfer(cap, *option::borrow(&self.buyer));
    }

    public fun claim_funds(cap: &PropertyCap, self: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(cap.to == object::id(self), ENotOwner);
        assert!(self.dispute, ERetailerPending);

        // Transfer the balance
        let amount = balance::value(&self.escrow);
        let refund = coin::take(&mut self.escrow, amount, ctx);
        transfer::public_transfer(refund, sender(ctx));
    }

    public fun set_retailer_pending(cap: &PropertyCap, self: &mut PropertyListing) {
        assert!(cap.to == object::id(self), ENotOwner);
        self.propertySubmitted = true;
    }
}
