import nacl from 'tweetnacl';
import bs58 from 'bs58';
import { PublicKey } from '@solana/web3.js';

/**
 * Verify Solana wallet signature
 * @param {string} walletAddress - Base58 encoded public key
 * @param {string} signature - Base58 encoded signature
 * @param {string} message - Original message that was signed
 * @returns {boolean} - True if signature is valid
 */
export function verifyWalletSignature(walletAddress, signature, message) {
  try {
    // Validate wallet address
    const publicKey = new PublicKey(walletAddress);
    const publicKeyBytes = publicKey.toBytes();
    
    // Decode signature from base58
    const signatureBytes = bs58.decode(signature);
    
    // Convert message to Uint8Array
    const messageBytes = new TextEncoder().encode(message);
    
    // Verify signature using nacl
    const verified = nacl.sign.detached.verify(
      messageBytes,
      signatureBytes,
      publicKeyBytes
    );
    
    return verified;
  } catch (error) {
    console.error('Signature verification error:', error);
    return false;
  }
}

/**
 * Generate a nonce for wallet signature
 * @returns {string} - Random nonce
 */
export function generateNonce() {
  return `Sign this message to authenticate with SpinMaster: ${Date.now()}-${Math.random().toString(36).substring(7)}`;
}

/**
 * Validate nonce timestamp (prevent replay attacks)
 * @param {string} nonce - Nonce to validate
 * @param {number} maxAgeMs - Maximum age in milliseconds (default: 5 minutes)
 * @returns {boolean} - True if nonce is still valid
 */
export function validateNonceTimestamp(nonce, maxAgeMs = 5 * 60 * 1000) {
  try {
    const match = nonce.match(/(\d+)-/);
    if (!match) return false;
    
    const timestamp = parseInt(match[1]);
    const now = Date.now();
    
    return (now - timestamp) <= maxAgeMs;
  } catch (error) {
    return false;
  }
}
