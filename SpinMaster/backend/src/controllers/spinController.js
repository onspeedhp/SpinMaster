import { db } from '../config/database.js';
import { generateSpinResult, canSpin, canClaimDailySpin } from '../utils/spinLogic.js';

/**
 * POST /api/spin/daily-claim
 * Claim daily free spin
 */
export const claimDailySpin = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user data
    const user = await db.getUserByWallet(req.user.walletAddress);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user can claim
    if (!canClaimDailySpin(user.last_daily_claim_at)) {
      const lastClaim = new Date(user.last_daily_claim_at);
      const nextClaim = new Date(lastClaim.getTime() + 24 * 60 * 60 * 1000);
      
      return res.status(429).json({ 
        error: 'Daily spin already claimed',
        nextClaimAt: nextClaim.toISOString()
      });
    }

    // Update user's daily claim timestamp and add 1 spin
    await db.updateDailyClaim(userId);
    const updatedUser = await db.updateUserSpins(userId, 1);

    res.json({
      message: 'Daily free spin claimed successfully',
      spinsBalance: updatedUser.spins_balance
    });
  } catch (error) {
    console.error('Daily claim error:', error);
    res.status(500).json({ error: 'Failed to claim daily spin' });
  }
};

/**
 * GET /api/spin/configuration
 * Get official wheel configuration
 */
export const getWheelConfig = async (req, res) => {
  try {
    const config = await db.getRewardsConfig();
    res.json({ config });
  } catch (error) {
    console.error('Get wheel config error:', error);
    res.status(500).json({ error: 'Failed to get wheel configuration' });
  }
};

/**
 * POST /api/spin/execute
 * Execute a spin and generate result server-side
 */
export const executeSpin = async (req, res) => {
  try {
    const userId = req.user.userId;

    console.log(`[SPIN] Request received | User: ${req.user.walletAddress}`);

    // Get user data
    const user = await db.getUserByWallet(req.user.walletAddress);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user has spins
    if (!canSpin(user.spins_balance)) {
      console.log(`[SPIN] Failed: Insufficient spins | User: ${req.user.walletAddress}`);
      return res.status(400).json({ error: 'Insufficient spins' });
    }

    // Get rewards configuration from DB
    const rewards = await db.getRewardsConfig();

    // Generate spin result server-side using DB config
    const result = generateSpinResult(rewards);

    // Deduct 1 spin from balance
    await db.updateUserSpins(userId, -1);

    // Record spin in history (Trigger in DB will handle adding back extra spins if reward_type is 'extra_spin')
    await db.createSpinRecord(userId, result.message, result.type, result.value, result.symbol);

    console.log(`[SPIN] Result generated | User: ${req.user.walletAddress} | Index: ${result.index} | Type: ${result.type} | Value: ${result.value} | Symbol: ${result.symbol || 'N/A'}`);

    // Get updated user data
    const updatedUser = await db.getUserByWallet(req.user.walletAddress);

    res.json({
      result: {
        index: result.index,
        type: result.type,
        value: result.value,
        message: result.message
      },
      spinsBalance: updatedUser.spins_balance,
      totalRewards: updatedUser.total_rewards
    });
  } catch (error) {
    console.error(`[SPIN] Error | User: ${req.user?.walletAddress} | ${error.message}`);
    res.status(500).json({ error: 'Failed to execute spin' });
  }
};

/**
 * GET /api/spin/history
 * Get user's spin history
 */
export const getSpinHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    const limit = parseInt(req.query.limit) || 50;

    const history = await db.getSpinHistory(userId, limit);

    res.json({ history });
  } catch (error) {
    console.error('Get spin history error:', error);
    res.status(500).json({ error: 'Failed to get spin history' });
  }
};
