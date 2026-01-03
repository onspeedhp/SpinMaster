import { db } from '../config/database.js';
import { verifyTransaction, getSpinPackage } from '../utils/solanaVerify.js';

/**
 * GET /api/payment/packages
 * Get available spin packages
 */
export const getPackages = async (req, res) => {
  try {
    const packages = [
      { id: 10, ...getSpinPackage(10) },
      { id: 25, ...getSpinPackage(25) },
      { id: 50, ...getSpinPackage(50) }
    ];

    res.json({ 
      packages,
      treasuryWallet: process.env.TREASURY_WALLET
    });
  } catch (error) {
    console.error('Get packages error:', error);
    res.status(500).json({ error: 'Failed to get packages' });
  }
};

/**
 * POST /api/payment/purchase-spins
 * Verify payment and add spins to user balance
 */
export const purchaseSpins = async (req, res) => {
  try {
    const { txSignature, packageId } = req.body;
    
    console.log(`[PURCHASE] Request received | User: ${req.user.walletAddress} | Package: ${packageId} | TX: ${txSignature}`);

    const userId = req.user.userId;
    const walletAddress = req.user.walletAddress;

    if (!txSignature || !packageId) {
      return res.status(400).json({ error: 'Transaction signature and package ID required' });
    }

    // Get package details
    const pkg = getSpinPackage(packageId);
    if (!pkg) {
      return res.status(400).json({ error: 'Invalid package ID' });
    }

    // Check if transaction already processed (prevent double-spend)
    const existingTx = await db.getTransactionBySignature(txSignature);
    if (existingTx) {
      console.log(`[PURCHASE] Failed: TX already used | TX: ${txSignature}`);
      return res.status(400).json({ error: 'Transaction already processed' });
    }

    // Verify transaction on Solana blockchain
    const verification = await verifyTransaction(
      txSignature,
      walletAddress,
      pkg.price
    );

    if (!verification.valid) {
      console.log(`[PURCHASE] Failed: Invalid verification | TX: ${txSignature} | Reason: ${verification.error}`);
      return res.status(400).json({ error: verification.error });
    }

    // Add spins to user balance
    const updatedUser = await db.updateUserSpins(userId, pkg.spins);

    // Record transaction
    await db.createTransaction(
      userId,
      txSignature,
      verification.amount,
      pkg.spins
    );

    console.log(`[PURCHASE] Success | User: ${walletAddress} | Spins Added: ${pkg.spins}`);

    res.json({
      message: `Successfully purchased ${pkg.spins} spins`,
      spinsBalance: updatedUser.spins_balance,
      transaction: {
        signature: txSignature,
        amount: verification.amount,
        spinsAdded: pkg.spins
      }
    });
  } catch (error) {
    console.error(`[PURCHASE] Error | User: ${req.user?.walletAddress} | ${error.message}`);
    res.status(500).json({ error: 'Failed to process purchase' });
  }
};
