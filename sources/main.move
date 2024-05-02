module Marketplace::main {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Option, none, some, is_some, contains, borrow};

    // Errors
    const EInvalidBid: u64 = 1;
    const EInvalidProperty: u64 = 2;
    const EDispute: u64 = 3;
    const EAlreadyResolved: u64 = 4;
    const ENotOwner: u64 = 5;
    const EInvalidWithdrawal: u64 = 6;

    // Struct definitions
    struct PropertyListing has key, store {
        id: UID,
        owner: address,
        buyer: Option<address>,
        description: vector<u8>,
        price: u64,
        escrow: Balance<SUI>,
        propertySubmitted: bool,
        dispute: bool,
        sellerRating: Option<u8>, // New field to store seller rating
        buyerRating: Option<u8>,  // New field to store buyer rating
    }

    // Accessors
    public entry fun get_listing_description(listing: &PropertyListing): vector<u8> {
        listing.description
    }

    public entry fun get_listing_price(listing: &PropertyListing): u64 {
        listing.price
    }

    // Public - Entry functions
    public entry fun create_listing(description: vector<u8>, price: u64, ctx: &mut TxContext) {
        
        let listing_id = object::new(ctx);
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
    }

    public entry fun place_bid(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(!is_some(&listing.buyer), EInvalidBid);
        listing.buyer = some(tx_context::sender(ctx));
    }

    public entry fun submit_property(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(contains(&listing.buyer, &tx_context::sender(ctx)), EInvalidProperty);
        listing.propertySubmitted = true;
    }

    public entry fun dispute_listing(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), EDispute);
        listing.dispute = true;
    }

    public entry fun resolve_dispute(listing: &mut PropertyListing, resolved: bool, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), EDispute);
        assert!(listing.dispute, EAlreadyResolved);
        assert!(is_some(&listing.buyer), EInvalidBid);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        if (resolved) {
            let buyer = *borrow(&listing.buyer);
            // Transfer funds to the buyer
            transfer::public_transfer(escrow_coin, buyer);
        } else {
            // Refund funds to the owner
            transfer::public_transfer(escrow_coin, listing.owner);
        };

        // Reset listing state
        listing.buyer = none();
        listing.propertySubmitted = false;
        listing.dispute = false;
    }

    public entry fun complete_purchase(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        assert!(listing.propertySubmitted && !listing.dispute, EInvalidProperty);
        assert!(is_some(&listing.buyer), EInvalidBid);
        let buyer = *borrow(&listing.buyer);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        // Transfer funds to the buyer
        transfer::public_transfer(escrow_coin, buyer);

        // Mark the listing as sold
        listing.buyerRating = none(); // Initialize buyer rating
        listing.sellerRating = none(); // Initialize seller rating

        // Reset listing state
        listing.buyer = none();
        listing.propertySubmitted = false;
        listing.dispute = false;
    }

    // Additional functions
    public entry fun cancel_listing(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx) || contains(&listing.buyer, &tx_context::sender(ctx)), ENotOwner);
        
        // Refund funds to the owner if not yet purchased
        if (is_some(&listing.buyer) && !listing.propertySubmitted && !listing.dispute) {
            let escrow_amount = balance::value(&listing.escrow);
            let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
            transfer::public_transfer(escrow_coin, listing.owner);
        };

        // Reset listing state
        listing.buyer = none();
        listing.propertySubmitted = false;
        listing.dispute = false;
    }

    public entry fun update_listing_description(listing: &mut PropertyListing, new_description: vector<u8>, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        listing.description = new_description;
    }

    public entry fun update_listing_price(listing: &mut PropertyListing, new_price: u64, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        listing.price = new_price;
    }

    public entry fun add_funds_to_listing(listing: &mut PropertyListing, amount: Coin<SUI>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listing.owner, ENotOwner);
        let added_balance = coin::into_balance(amount);
        balance::join(&mut listing.escrow, added_balance);
    }

    public entry fun request_withdrawal(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listing.owner, ENotOwner);
        assert!(listing.propertySubmitted == false, EInvalidWithdrawal);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        // Refund funds to the owner
        transfer::public_transfer(escrow_coin, listing.owner);

        // Reset listing state
        listing.buyer = none();
        listing.propertySubmitted = false;
        listing.dispute = false;
    }
       // Function to extend the dispute period of a property listing
    public entry fun extend_dispute_period(listing: &mut PropertyListing, extension_days: u64, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        assert!(listing.dispute, EDispute);
        // Additional logic to extend the dispute period
        // For example, you could update a timestamp indicating the new dispute end time
    }
     // Function to mark a property listing as sold
    public entry fun mark_listing_as_sold(listing: &mut PropertyListing, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        assert!(listing.propertySubmitted && !listing.dispute, EInvalidProperty);
        assert!(is_some(&listing.buyer), EInvalidBid);
        // Additional logic to mark the listing as sold
        listing.sellerRating = some(5); // Example: Seller gets a rating of 5 (out of 5)
    }
    // Function to transfer ownership of a property listing
    public entry fun transfer_listing_ownership(listing: &mut PropertyListing, new_owner: address, ctx: &mut TxContext) {
        assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
        // Additional logic to transfer ownership of the listing to the new owner
    }
     // Function to retrieve the current owner of a property listing
    public entry fun get_listing_owner(listing: &PropertyListing): address {
        listing.owner
    }
     // Function to retrieve the current buyer of a property listing
    public entry fun get_listing_buyer(listing: &PropertyListing): Option<address> {
        listing.buyer
    }
    // Function to update property details
    public entry fun update_property_details(listing: &mut PropertyListing, new_details: vector<u8>, ctx: &mut TxContext) {
    // Only the owner can update property details
    assert!(listing.owner == tx_context::sender(ctx), ENotOwner);
    
    // Additional logic to update property details
    listing.description = new_details;
    }  
}
