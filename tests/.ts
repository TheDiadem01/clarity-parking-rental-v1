import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test parking space registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('parking-rental', 'register-parking-space', [
                types.ascii("123 Main St"),
                types.uint(10)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Try registering same space again
        let block2 = chain.mineBlock([
            Tx.contractCall('parking-rental', 'register-parking-space', [
                types.ascii("123 Main St"),
                types.uint(10)
            ], wallet1.address)
        ]);
        
        block2.receipts[0].result.expectErr(types.uint(102)); // err-already-registered
    }
});

Clarinet.test({
    name: "Test parking space rental flow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const owner = accounts.get('wallet_1')!;
        const renter = accounts.get('wallet_2')!;
        
        // Register parking space
        let block1 = chain.mineBlock([
            Tx.contractCall('parking-rental', 'register-parking-space', [
                types.ascii("123 Main St"),
                types.uint(10)
            ], owner.address)
        ]);
        
        block1.receipts[0].result.expectOk();
        
        // Rent the space
        let block2 = chain.mineBlock([
            Tx.contractCall('parking-rental', 'rent-space', [
                types.principal(owner.address),
                types.uint(24)
            ], renter.address)
        ]);
        
        block2.receipts[0].result.expectOk();
        
        // Try renting unavailable space
        let block3 = chain.mineBlock([
            Tx.contractCall('parking-rental', 'rent-space', [
                types.principal(owner.address),
                types.uint(24)
            ], deployer.address)
        ]);
        
        block3.receipts[0].result.expectErr(types.uint(103)); // err-not-available
    }
});
