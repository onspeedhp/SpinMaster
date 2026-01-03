import { db } from '../config/database.js';
import { verifyWalletSignature, generateNonce, validateNonceTimestamp } from '../utils/solanaAuth.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../middleware/auth.js';

// Store nonces temporarily (in production, use Redis)
const nonceStore = new Map();

/**
 * GET /api/auth/nonce
 * Generate a nonce for wallet signature
 */
export const getNonce = async (req, res) => {
  try {
    const { walletAddress } = req.query;

    if (!walletAddress) {
      return res.status(400).json({ error: 'Wallet address required' });
    }

    const nonce = generateNonce();
    
    // Store nonce with expiration (5 minutes)
    nonceStore.set(walletAddress, nonce);
    setTimeout(() => nonceStore.delete(walletAddress), 5 * 60 * 1000);

    console.log(`[AUTH] Nonce requested | User: ${walletAddress}`);

    res.json({ nonce });
  } catch (error) {
    console.error('Get nonce error:', error);
    res.status(500).json({ error: 'Failed to generate nonce' });
  }
};

/**
 * POST /api/auth/login
 * Verify wallet signature and issue JWT tokens
 */
export const login = async (req, res) => {
  try {
    const { walletAddress, signature } = req.body;

    if (!walletAddress || !signature) {
      return res.status(400).json({ error: 'Wallet address and signature required' });
    }

    // Get stored nonce
    const nonce = nonceStore.get(walletAddress);
    if (!nonce) {
      return res.status(400).json({ error: 'Nonce not found or expired. Please request a new nonce.' });
    }

    // Validate nonce timestamp
    if (!validateNonceTimestamp(nonce)) {
      nonceStore.delete(walletAddress);
      return res.status(400).json({ error: 'Nonce expired. Please request a new nonce.' });
    }

    // Verify signature
    const isValid = verifyWalletSignature(walletAddress, signature, nonce);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    // Delete used nonce (prevent replay attacks)
    nonceStore.delete(walletAddress);

    // Get or create user
    let user = await db.getUserByWallet(walletAddress);
    if (!user) {
      user = await db.createUser(walletAddress);
    }

    // Generate tokens
    const tokenPayload = {
      userId: user.id,
      walletAddress: user.wallet_address
    };

    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    console.log(`[AUTH] Login successful | User: ${walletAddress} | ID: ${user.id}`);

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        walletAddress: user.wallet_address,
        spinsBalance: user.spins_balance,
        totalSpins: user.total_spins,
        totalRewards: user.total_rewards
      }
    });
  } catch (error) {
    console.error(`[AUTH] Login error | User: ${req.body.walletAddress} | Error: ${error.message}`);
    res.status(500).json({ error: 'Login failed' });
  }
};

/**
 * POST /api/auth/refresh
 * Refresh access token using refresh token
 */
export const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);

    // Generate new access token
    const tokenPayload = {
      userId: decoded.userId,
      walletAddress: decoded.walletAddress
    };

    const accessToken = generateAccessToken(tokenPayload);

    res.json({ accessToken });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Refresh token expired. Please login again.' });
    }
    res.status(403).json({ error: 'Invalid refresh token' });
  }
};

/**
 * POST /api/auth/logout
 * Logout user (client should delete tokens)
 */
export const logout = async (req, res) => {
  // In a production app, you'd invalidate the refresh token in database/Redis
  res.json({ message: 'Logged out successfully' });
};
