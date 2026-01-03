import { pool } from '../src/config/database.js';

async function checkLatestSpins() {
  try {
    console.log('🔍 Checking latest spins in database...');
    
    const result = await pool.query(`
      SELECT s.id, s.result, s.reward_type, s.reward_value, s.symbol, s.created_at, u.wallet_address 
      FROM spins s
      JOIN users u ON s.user_id = u.id
      ORDER BY s.created_at DESC 
      LIMIT 5
    `);

    if (result.rows.length === 0) {
      console.log('No spins found in database.');
    } else {
      console.log(`✅ Found ${result.rows.length} recent spins:`);
      result.rows.forEach((row, i) => {
        console.log(`\n[${i+1}] Time: ${row.created_at}`);
        console.log(`    User: ${row.wallet_address.substring(0, 6)}...`);
        console.log(`    Result: ${row.result}`);
        console.log(`    Type: ${row.reward_type}`);
        console.log(`    Value: ${row.reward_value}`);
        console.log(`    Symbol: ${row.symbol || 'N/A'}`);
      });
    }

    // Check user balance to verify consistency
    if (result.rows.length > 0) {
        const lastUser = result.rows[0].wallet_address;
        const userRes = await pool.query('SELECT spins_balance FROM users WHERE wallet_address = $1', [lastUser]);
        console.log(`\nCurrent balance for last user: ${userRes.rows[0]?.spins_balance}`);
    }

  } catch (error) {
    console.error('❌ Error checking spins:', error);
  } finally {
    await pool.end();
  }
}

checkLatestSpins();
