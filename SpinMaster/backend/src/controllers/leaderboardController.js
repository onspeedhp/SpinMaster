import { db } from '../config/database.js';

/**
 * GET /api/leaderboard/:period
 * Get leaderboard for specified period
 * Periods: daily, weekly, all-time
 */
export const getLeaderboard = async (req, res) => {
  try {
    const { period } = req.params;
    const limit = parseInt(req.query.limit) || 100;

    if (!['daily', 'weekly', 'all-time'].includes(period)) {
      return res.status(400).json({ error: 'Invalid period. Use: daily, weekly, or all-time' });
    }

    const leaderboard = await db.getLeaderboard(period, limit);

    // Add rank to each entry
    const rankedLeaderboard = leaderboard.map((entry, index) => ({
      rank: index + 1,
      walletAddress: entry.wallet_address,
      username: entry.username || `Player ${entry.id}`,
      totalRewards: entry.total_rewards,
      totalSpins: entry.total_spins
    }));

    res.json({
      period,
      leaderboard: rankedLeaderboard
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ error: 'Failed to get leaderboard' });
  }
};
