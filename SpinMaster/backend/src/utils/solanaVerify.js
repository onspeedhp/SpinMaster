import { Connection, PublicKey } from '@solana/web3.js';
import dotenv from 'dotenv';

dotenv.config();

const SOLANA_RPC_URL = process.env.SOLANA_RPC_URL || 'https://api.devnet.solana.com';
const TREASURY_WALLET = process.env.TREASURY_WALLET;

const connection = new Connection(SOLANA_RPC_URL, 'confirmed');

/**
 * Verify Solana transaction on-chain
 * @param {string} txSignature - Transaction signature to verify
 * @param {string} userWallet - User's wallet address (sender)
 * @param {number} expectedAmount - Expected amount in lamports
 * @returns {Promise<object>} - Verification result
 */
export async function verifyTransaction(txSignature, userWallet, expectedAmount) {
  try {
    // Fetch transaction from blockchain
    const transaction = await connection.getTransaction(txSignature, {
      maxSupportedTransactionVersion: 0
    });

    if (!transaction) {
      return {
        valid: false,
        error: 'Transaction not found on blockchain'
      };
    }

    // Check if transaction was successful
    if (transaction.meta?.err) {
      return {
        valid: false,
        error: 'Transaction failed on blockchain'
      };
    }

    // Get transaction details
    const { message } = transaction.transaction;
    const accountKeys = message.staticAccountKeys || message.accountKeys;
    
    // Verify sender (first account is always the fee payer/sender)
    const sender = accountKeys[0].toString();
    if (sender !== userWallet) {
      return {
        valid: false,
        error: 'Transaction sender does not match user wallet'
      };
    }

    // Verify receiver (treasury wallet)
    const receiver = accountKeys[1].toString();
    if (receiver !== TREASURY_WALLET) {
      return {
        valid: false,
        error: 'Transaction receiver does not match treasury wallet'
      };
    }

    // Verify amount
    const preBalances = transaction.meta.preBalances;
    const postBalances = transaction.meta.postBalances;
    
    // Calculate amount transferred (difference in receiver's balance)
    const amountTransferred = postBalances[1] - preBalances[1];
    
    if (amountTransferred < expectedAmount) {
      return {
        valid: false,
        error: `Insufficient payment. Expected ${expectedAmount} lamports, received ${amountTransferred}`
      };
    }

    return {
      valid: true,
      amount: amountTransferred,
      sender,
      receiver,
      timestamp: transaction.blockTime
    };
  } catch (error) {
    console.error('Transaction verification error:', error);
    return {
      valid: false,
      error: error.message || 'Failed to verify transaction'
    };
  }
}

/**
 * Get spin package details
 * @param {number} packageId - Package ID (10, 25, or 50)
 * @returns {object} - Package details
 */
export function getSpinPackage(packageId) {
  const packages = {
    10: {
      spins: 10,
      price: parseInt(process.env.PACKAGE_10_SPINS_PRICE) || 100000000, // 0.1 SOL
      name: 'Starter Pack'
    },
    25: {
      spins: 25,
      price: parseInt(process.env.PACKAGE_25_SPINS_PRICE) || 200000000, // 0.2 SOL
      name: 'Pro Pack'
    },
    50: {
      spins: 50,
      price: parseInt(process.env.PACKAGE_50_SPINS_PRICE) || 350000000, // 0.35 SOL
      name: 'Premium Pack'
    }
  };

  return packages[packageId] || null;
}
