# Property Marketplace Smart Contract Documentation

## Overview

The Property Marketplace Smart Contract is a decentralized application (DApp) built on the SUI blockchain that enables users to create, buy, sell, and manage property listings in a secure and transparent manner. This documentation provides a comprehensive guide on how to interact with the smart contract, covering its features, setup process, and usage instructions.

## Purpose

The primary purpose of the Property Marketplace Smart Contract is to facilitate property transactions within a decentralized marketplace. It aims to offer users a reliable platform for listing properties, placing bids, resolving disputes, and completing transactions without relying on traditional intermediaries.

## Features

1. **Property Listing Creation**: Users can create new property listings by providing essential details such as property description, price, and ownership status.

2. **Bid Placement**: Participants can place bids on active property listings, competing with other potential buyers to secure the winning bid.

3. **Dispute Resolution**: The smart contract includes mechanisms for handling disputes between buyers and sellers, ensuring fair outcomes in case of conflicts.

4. **Transaction Management**: Sellers can manage property transactions, including marking listings as sold, canceling listings, and withdrawing funds.

5. **Rating System**: The contract supports a rating system for both buyers and sellers, allowing participants to evaluate each other based on their transaction experiences.

## Setup

### Prerequisites

1. Rust and Cargo: Install Rust and Cargo using the following command:

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

2. SUI Blockchain: Install the SUI blockchain client by following the instructions provided in the [SUI GitHub repository](https://github.com/MystenLabs/sui).

3. SUI Wallet (Optional): Install the SUI Wallet extension for your web browser from the [Chrome Web Store](https://chrome.google.com/webstore/detail/sui-wallet/opcgpfmipidbgpenhmajoajpbobppdil?hl=en-GB).

### Build and Deploy

1. Clone the Property Marketplace repository and navigate to the project directory.

2. Build the smart contract package using the SUI CLI:

3. Publish the smart contract package to the SUI blockchain:
sui client publish --gas-budget 100000000 --json

4. Extract relevant object IDs from the publish output, including the package ID and other necessary identifiers.

## Usage

### Creating a Listing

To create a new property listing, invoke the `create_listing` function with the property details and transaction context.

### Placing a Bid

Participants can place bids on active property listings using the `place_bid` function. Ensure that the listing is open for bidding and provide the necessary transaction context.

### Submitting Property Details

Once a bid is accepted, the buyer can submit property details using the `submit_property` function, confirming the transaction's validity.

### Managing Disputes

In case of disputes, the `dispute_listing` function allows the seller to initiate dispute resolution procedures, ensuring fair outcomes for both parties.

### Completing a Purchase

Once the transaction is finalized, sellers can complete the purchase using the `complete_purchase` function, transferring ownership of the property to the buyer and releasing escrow funds.

### Additional Functions

- **Cancel Listing**: Sellers can cancel listings and refund funds if the property remains unsold.
- **Update Listing Details**: Sellers can update property details such as description and price.
- **Add Funds to Listing**: Sellers can add additional funds to the escrow account for a specific listing.
- **Request Withdrawal**: Sellers can request withdrawal of funds from the escrow account under certain conditions.
- **Extend Dispute Period**: Sellers can extend the dispute period for active listings to allow more time for resolution.
- **Mark Listing as Sold**: Sellers can mark listings as sold and provide ratings for buyers.

## Interacting with the Smart Contract

### Using the SUI CLI

1. Use the SUI CLI to interact with the smart contract functions, providing necessary arguments such as listing IDs, bid amounts, and transaction contexts.

2. Monitor transaction outputs and blockchain events to track the status of property listings and transactions.

### Using the SUI Wallet (Optional)

1. Import your SUI wallet address into the SUI Wallet extension.

2. Use the wallet interface to interact with the smart contract functions, simplifying the process of creating listings, placing bids, and managing transactions.

## Conclusion

The Property Marketplace Smart Contract offers a decentralized solution for property transactions, promoting transparency, security, and efficiency in the real estate marketplace. By leveraging blockchain technology, users can participate in property transactions with confidence, knowing that their transactions are secure and verifiable on the SUI blockchain.
