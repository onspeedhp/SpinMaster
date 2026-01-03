import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const { Pool } = pg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ Missing DATABASE_URL environment variable');
  process.exit(1);
}

async function applyUpdate() {
  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  try {
    console.log('🚀 Starting database update...');
    
    // Read update file
    const updatePath = path.join(__dirname, 'update_rewards_logic.sql');
    if (!fs.existsSync(updatePath)) {
        console.error('❌ update_rewards_logic.sql not found at ' + updatePath);
        process.exit(1);
    }
    const sql = fs.readFileSync(updatePath, 'utf8');
    
    console.log('📄 Executing update_rewards_logic.sql...');
    await pool.query(sql);
    
    console.log('✅ Update completed successfully!');

    // Show new config
    const configResult = await pool.query('SELECT * FROM rewards_config ORDER BY segment_index');
    console.log('\n📊 New Rewards Configuration:');
    configResult.rows.forEach(row => {
        console.log(`  [${row.segment_index}] ${row.reward_type} - ${row.label} (Weight: ${row.weight})`);
    });
    
  } catch (error) {
    console.error('❌ Update failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

applyUpdate();
