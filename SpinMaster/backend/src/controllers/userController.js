import { db } from '../config/database.js';

/**
 * GET /api/user/profile
 * Get user profile
 */
export const getProfile = async (req, res) => {
  try {
    const user = await db.getUserByWallet(req.user.walletAddress);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user: {
        id: user.id,
        walletAddress: user.wallet_address,
        username: user.username,
        spinsBalance: user.spins_balance,
        totalSpins: user.total_spins,
        totalRewards: user.total_rewards,
        lastDailyClaimAt: user.last_daily_claim_at,
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
};

/**
 * GET /api/user/spins
 * Get user's spin balance
 */
export const getSpinsBalance = async (req, res) => {
  try {
    const user = await db.getUserByWallet(req.user.walletAddress);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      spinsBalance: user.spins_balance
    });
  } catch (error) {
    console.error('Get spins balance error:', error);
    res.status(500).json({ error: 'Failed to get spins balance' });
  }
};
