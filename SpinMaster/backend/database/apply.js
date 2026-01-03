import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

const { Pool } = pg;

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ Missing DATABASE_URL in .env file');
  process.exit(1);
}

const sqlFile = process.argv[2];

if (!sqlFile) {
  console.error('❌ Please specify a SQL file to apply.');
  console.error('Example: node database/apply.js database/rewards_config.sql');
  process.exit(1);
}

async function applySql() {
  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  try {
    const absolutePath = path.resolve(sqlFile);
    if (!fs.existsSync(absolutePath)) {
      console.error(`❌ File not found: ${sqlFile}`);
      process.exit(1);
    }

    const sql = fs.readFileSync(absolutePath, 'utf8');
    
    console.log(`🚀 Applying ${path.basename(sqlFile)} to database...`);
    await pool.query(sql);
    console.log('✅ Applied successfully!');
    
  } catch (error) {
    console.error('❌ Failed to apply SQL:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

applySql();
