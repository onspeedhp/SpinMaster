/**
 * Server-side spin result generation with weighted probabilities
 * This ensures clients cannot manipulate spin results
 */

/**
 * Generate random spin result based on weighted probabilities
 * @param {Array} rewards - List of active rewards from database
 * @returns {object} - Spin result with type, value, and display message
 */
export function generateSpinResult(rewards) {
  // Use provided rewards or fallback to empty array
  const activeRewards = rewards && rewards.length > 0 ? rewards : [];
  
  if (activeRewards.length === 0) {
    return {
      index: 1, // Fallback to "Good Luck"
      type: 'none',
      value: 0,
      message: 'Better luck next time!'
    };
  }

  // Calculate total weight
  const totalWeight = activeRewards.reduce((sum, reward) => sum + parseFloat(reward.weight), 0);
  
  // Generate random number
  let random = Math.random() * totalWeight;
  
  // Select reward based on weight
  for (const reward of activeRewards) {
    random -= parseFloat(reward.weight);
    if (random <= 0) {
      return {
        index: reward.index || reward.segment_index,
        type: reward.type || reward.reward_type,
        value: reward.value || reward.reward_value,
        symbol: reward.symbol,
        message: reward.message || reward.label
      };
    }
  }
  
  // Fallback (should never reach here)
  return {
    type: 'none',
    value: 0,
    message: 'Better luck next time!'
  };
}

/**
 * Get display message for reward
 * @param {string} type - Reward type
 * @param {number} value - Reward value
 * @returns {string} - Display message
 */
function getRewardMessage(type, value) {
  switch (type) {
    case 'points':
      return `You won ${value} points!`;
    case 'extra_spin':
      return `You won ${value} extra spin${value > 1 ? 's' : ''}!`;
    case 'jackpot':
      return `🎉 JACKPOT! You won ${value} points!`;
    default:
      return `You won a prize!`;
  }
}

/**
 * Validate if user has enough spins
 * @param {number} currentBalance - User's current spin balance
 * @returns {boolean} - True if user can spin
 */
export function canSpin(currentBalance) {
  return currentBalance > 0;
}

/**
 * Check if user can claim daily free spin
 * @param {Date|null} lastClaimDate - Last time user claimed daily spin
 * @returns {boolean} - True if user can claim
 */
export function canClaimDailySpin(lastClaimDate) {
  if (!lastClaimDate) return true;
  
  const now = new Date();
  const lastClaim = new Date(lastClaimDate);
  const hoursSinceLastClaim = (now - lastClaim) / (1000 * 60 * 60);
  
  return hoursSinceLastClaim >= 24;
}
