import { pool } from '../src/config/database.js';

const clear = async () => {
  try {
    console.log('Clearing data...');
    await pool.query('TRUNCATE TABLE transactions CASCADE');
    await pool.query('TRUNCATE TABLE spins CASCADE');
    await pool.query('TRUNCATE TABLE users CASCADE');
    console.log('✅ Cleared users, spins, and transactions.');
  } catch (error) {
    console.error('❌ Error clearing data:', error);
  } finally {
    await pool.end();
    process.exit();
  }
};

clear();
