import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const databaseUrl = process.env.DATABASE_URL;

async function updateUsdtLogo() {
  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  try {
    console.log('🚀 Updating USDT Logo URL...');
    
    const safeUrl = 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB/logo.png';
    // Wikimedia URL causing issues: https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/USDT_Logo.png/1024px-USDT_Logo.png
    
    // Update for symbol USDT
    const query = `
      UPDATE rewards_config 
      SET icon_url = $1
      WHERE symbol = 'USDT'
    `;
    
    await pool.query(query, [safeUrl]);
    console.log('✅ USDT Logo updated successfully!');
    
    // Optional: Verify
    const verify = await pool.query("SELECT icon_url FROM rewards_config WHERE symbol = 'USDT'");
    console.log('Current URL in DB:', verify.rows[0]?.icon_url);
    
  } catch (error) {
    console.error('❌ Failed to update USDT logo:', error.message);
  } finally {
    await pool.end();
  }
}

updateUsdtLogo();
