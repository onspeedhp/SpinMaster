import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('Missing DATABASE_URL environment variable');
}

// Create PostgreSQL connection pool
export const pool = new Pool({
  connectionString: databaseUrl,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

// Database helper functions
export const db = {
  // Users
  async getUserByWallet(walletAddress) {
    const query = 'SELECT * FROM users WHERE wallet_address = $1';
    const result = await pool.query(query, [walletAddress]);
    return result.rows[0] || null;
  },

  async createUser(walletAddress) {
    const query = `
      INSERT INTO users (wallet_address, spins_balance, total_spins, total_rewards)
      VALUES ($1, 0, 0, 0)
      RETURNING *
    `;
    const result = await pool.query(query, [walletAddress]);
    return result.rows[0];
  },

  async updateUserSpins(userId, spinsToAdd) {
    const query = `
      UPDATE users
      SET spins_balance = spins_balance + $1
      WHERE id = $2
      RETURNING *
    `;
    const result = await pool.query(query, [spinsToAdd, userId]);
    return result.rows[0];
  },

  async updateDailyClaim(userId) {
    const query = `
      UPDATE users
      SET last_daily_claim_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    const result = await pool.query(query, [userId]);
    return result.rows[0];
  },

  // Spins
  async createSpinRecord(userId, result, rewardType, rewardValue, symbol) {
    const query = `
      INSERT INTO spins (user_id, result, reward_type, reward_value, symbol)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    const queryResult = await pool.query(query, [userId, result, rewardType, rewardValue, symbol]);
    return queryResult.rows[0];
  },

  async getSpinHistory(userId, limit = 50) {
    const query = `
      SELECT * FROM spins
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT $2
    `;
    const result = await pool.query(query, [userId, limit]);
    return result.rows;
  },

  // Transactions
  async createTransaction(userId, txSignature, amount, spinsAdded) {
    const query = `
      INSERT INTO transactions (user_id, tx_signature, amount, spins_added, status)
      VALUES ($1, $2, $3, $4, 'completed')
      RETURNING *
    `;
    const result = await pool.query(query, [userId, txSignature, amount, spinsAdded]);
    return result.rows[0];
  },

  async getTransactionBySignature(txSignature) {
    const query = 'SELECT * FROM transactions WHERE tx_signature = $1';
    const result = await pool.query(query, [txSignature]);
    return result.rows[0] || null;
  },

  // Leaderboard
  async getLeaderboard(period = 'all_time', limit = 100) {
    const query = `
      SELECT id, wallet_address, username, total_rewards, total_spins
      FROM users
      ORDER BY total_rewards DESC
      LIMIT $1
    `;
    const result = await pool.query(query, [limit]);
    return result.rows;
  },

  // Configuration
  async getRewardsConfig() {
    const query = `
      SELECT segment_index, reward_type, reward_value, symbol, label, weight, color_hex, icon_url
      FROM rewards_config
      WHERE is_active = TRUE
      ORDER BY segment_index ASC
    `;
    const result = await pool.query(query);
    return result.rows;
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing database pool');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT signal received: closing database pool');
  await pool.end();
  process.exit(0);
});
