module property_marketplace::main {
   use sui::transfer;
   use sui::sui::SUI;
   use sui::coin::{Self, Coin};
   use sui::object::{Self, UID};
   use sui::balance::{Self, Balance};
   use sui::tx_context::{Self, TxContext};
   use std::option::{Option, none, some, is_some, contains, borrow};

   // Error structs
   struct EInvalidBid has drop {}
   struct EInvalidProperty has drop {}
   struct EDispute has drop {}
   struct EAlreadyResolved has drop {}
   struct ENotOwner has drop {}
   struct EInvalidWithdrawal has drop {}

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
       disputePeriodEndTime: u64, // Timestamp for dispute period end
       sellerRating: Option<u8>,
       buyerRating: Option<u8>,
   }

   // Module initializer
   struct PropertyMarketplaceConfig has key {
       id: UID,
       authorizedAddresses: vector<address>,
   }

   fun init(ctx: &mut TxContext) {
       transfer::share_object(PropertyMarketplaceConfig {
           id: object::new(ctx),
           authorizedAddresses: vector[tx_context::sender(ctx)],
       })
   }

   // Accessors
   public entry fun get_listing_description(listing: &PropertyListing): vector<u8> {
       listing.description
   }

   public entry fun get_listing_price(listing: &PropertyListing): u64 {
       listing.price
   }

   public entry fun get_seller_rating(listing: &PropertyListing): Option<u8> {
       listing.sellerRating
   }

   public entry fun get_buyer_rating(listing: &PropertyListing): Option<u8> {
       listing.buyerRating
   }

   // Helper functions
   fun is_authorized(addr: address, config: &PropertyMarketplaceConfig): bool {
       contains(&config.authorizedAddresses, &addr)
   }

   // Public - Entry functions
   public entry fun create_listing(
       description: vector<u8>,
       price: u64,
       ctx: &mut TxContext
   ) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);

       let listing_id = object::new(ctx);
       transfer::share_object(PropertyListing {
           id: listing_id,
           owner: sender,
           buyer: none(),
           description,
           price,
           escrow: balance::zero(),
           propertySubmitted: false,
           dispute: false,
           disputePeriodEndTime: 0, // Set to 0 initially
           sellerRating: none(),
           buyerRating: none(),
       });
   }

   public entry fun place_bid(listing: &mut PropertyListing, ctx: &mut TxContext) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(!is_some(&listing.buyer), EInvalidBid);
       listing.buyer = some(sender);
   }

   public entry fun submit_property(listing: &mut PropertyListing, ctx: &mut TxContext) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(contains(&listing.buyer, &sender), EInvalidProperty);
       listing.propertySubmitted = true;
   }

   public entry fun dispute_listing(listing: &mut PropertyListing, ctx: &mut TxContext) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(listing.owner == sender, EDispute);
       listing.dispute = true;
       listing.disputePeriodEndTime = tx_context::epoch(ctx) + 14 * 86400; // Set dispute period to 14 days
   }

   public entry fun resolve_dispute(
       listing: &mut PropertyListing,
       resolved: bool,
       ctx: &mut TxContext
   ) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(listing.owner == sender, EDispute);
       assert!(listing.dispute, EAlreadyResolved);
       assert!(tx_context::epoch(ctx) >= listing.disputePeriodEndTime, EAlreadyResolved); // Check if dispute period has ended
       assert!(is_some(&listing.buyer), EInvalidBid);
       let escrow_amount = balance::value(&listing.escrow);
       let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
       if (resolved) {
           let buyer = *borrow(&listing.buyer);
           transfer::public_transfer(escrow_coin, buyer); // Transfer funds to the buyer
       } else {
           transfer::public_transfer(escrow_coin, listing.owner); // Refund funds to the owner
       };

       // Reset listing state
       listing.buyer = none();
       listing.propertySubmitted = false;
       listing.dispute = false;
       listing.disputePeriodEndTime = 0;
   }

   public entry fun complete_purchase(listing: &mut PropertyListing, ctx: &mut TxContext) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(listing.owner == sender, ENotOwner);
       assert!(listing.propertySubmitted && !listing.dispute, EInvalidProperty);
       assert!(is_some(&listing.buyer), EInvalidBid);
       let buyer = *borrow(&listing.buyer);
       let escrow_amount = balance::value(&listing.escrow);
       let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
       transfer::public_transfer(escrow_coin, buyer); // Transfer funds to the buyer

       // Update ratings
       listing.buyerRating = some(5); // Example: Buyer gets a rating of 5 (out of 5)
       listing.sellerRating = some(4); // Example: Seller gets a rating of 4 (out of 5)

       // Reset listing state
       listing.buyer = none();
       listing.propertySubmitted = false;
       listing.dispute = false;
       listing.disputePeriodEndTime = 0;
   }

   // Additional functions
   public entry fun cancel_listing(listing: &mut PropertyListing, ctx: &mut TxContext) {
       let sender = tx_context::sender(ctx);
       assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
       assert!(listing.owner == sender || contains(&listing.buyer, &sender), ENotOwner);

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
       listing.disputePeriodEndTime = 0;
   }

   public entry fun update_listing_description(
    listing: &mut PropertyListing,
    new_description: vector<u8>,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    listing.description = new_description;
    }

    public entry fun update_listing_price(
    listing: &mut PropertyListing,
    new_price: u64,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    listing.price = new_price;
    }

    public entry fun add_funds_to_listing(
    listing: &mut PropertyListing,
    amount: Coin<SUI>,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(tx_context::sender(ctx) == listing.owner, ENotOwner);
    let added_balance = coin::into_balance(amount);
    balance::join(&mut listing.escrow, added_balance);
    }

    public entry fun request_withdrawal(listing: &mut PropertyListing, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(tx_context::sender(ctx) == listing.owner, ENotOwner);
    assert!(listing.propertySubmitted == false, EInvalidWithdrawal);
    let escrow_amount = balance::value(&listing.escrow);
    let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
    transfer::public_transfer(escrow_coin, listing.owner); // Refund funds to the owner

    // Reset listing state
    listing.buyer = none();
    listing.propertySubmitted = false;
    listing.dispute = false;
    listing.disputePeriodEndTime = 0;
    }

    // Function to extend the dispute period of a property listing
    public entry fun extend_dispute_period(
    listing: &mut PropertyListing,
    extension_days: u64,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    assert!(listing.dispute, EDispute);
    listing.disputePeriodEndTime = listing.disputePeriodEndTime + extension_days * 86400; // Extend dispute period by the specified number of days
    }

    // Function to mark a property listing as sold
    public entry fun mark_listing_as_sold(listing: &mut PropertyListing, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    assert!(listing.propertySubmitted && !listing.dispute, EInvalidProperty);
    assert!(is_some(&listing.buyer), EInvalidBid);
    listing.sellerRating = some(5); // Example: Seller gets a rating of 5 (out of 5)
    }

    // Function to transfer ownership of a property listing
    public entry fun transfer_listing_ownership(
    listing: &mut PropertyListing,
    new_owner: address,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    listing.owner = new_owner;
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
    public entry fun update_property_details(
    listing: &mut PropertyListing,
    new_details: vector<u8>,
    ctx: &mut TxContext
    ) {
    let sender = tx_context::sender(ctx);
    assert!(is_authorized(sender, borrow_global<PropertyMarketplaceConfig>()), ENotOwner);
    assert!(listing.owner == sender, ENotOwner);
    listing.description = new_details;
    }
}