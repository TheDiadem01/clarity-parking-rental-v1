import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new parking spot",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('parking-spot', 'register-parking-spot', [
                types.uint(1),
                types.uint(10)
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
    }
});

Clarinet.test({
    name: "Can rent an available parking spot",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('parking-spot', 'register-parking-spot', [
                types.uint(1),
                types.uint(10)
            ], wallet1.address),
            Tx.contractCall('parking-spot', 'rent-spot', [
                types.uint(1)
            ], wallet2.address)
        ]);
        
        assertEquals(block.receipts[1].result.expectOk(), true);
    }
});

Clarinet.test({
    name: "Can end rental of a parking spot",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('parking-spot', 'register-parking-spot', [
                types.uint(1),
                types.uint(10)
            ], wallet1.address),
            Tx.contractCall('parking-spot', 'rent-spot', [
                types.uint(1)
            ], wallet2.address),
            Tx.contractCall('parking-spot', 'end-rental', [
                types.uint(1)
            ], wallet2.address)
        ]);
        
        assertEquals(block.receipts[2].result.expectOk(), true);
    }
});
