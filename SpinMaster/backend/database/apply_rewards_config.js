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

async function applyRewardsConfig() {
  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  try {
    console.log('🚀 Creating rewards_config table...');
    const sqlPath = path.join(__dirname, 'rewards_config.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    await pool.query(sql);
    console.log('✅ rewards_config created and seeded successfully!');
  } catch (error) {
    console.error('❌ Failed to create rewards_config:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

applyRewardsConfig();
