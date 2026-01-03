-- SpinMaster Database Schema for Railway PostgreSQL

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_address TEXT UNIQUE NOT NULL,
  username TEXT,
  spins_balance INTEGER DEFAULT 0 CHECK (spins_balance >= 0),
  total_spins INTEGER DEFAULT 0,
  total_rewards NUMERIC(20, 8) DEFAULT 0,
  last_daily_claim_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on wallet_address for faster lookups
CREATE INDEX idx_users_wallet ON users(wallet_address);

-- Spins history table
CREATE TABLE spins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  result TEXT NOT NULL,
  reward_type TEXT NOT NULL CHECK (reward_type IN ('points', 'extra_spin', 'jackpot', 'token', 'none')),
  reward_value NUMERIC(20, 8) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX idx_spins_user_id ON spins(user_id);
CREATE INDEX idx_spins_created_at ON spins(created_at DESC);

-- Transactions table (payment records)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tx_signature TEXT UNIQUE NOT NULL,
  amount BIGINT NOT NULL,
  spins_added INTEGER NOT NULL,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on tx_signature for duplicate checking
CREATE INDEX idx_transactions_signature ON transactions(tx_signature);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to update total_spins, total_rewards and spins_balance after spin
CREATE OR REPLACE FUNCTION update_user_stats_after_spin()
RETURNS TRIGGER AS $$
BEGIN
  -- 1. Update general stats
  UPDATE users
  SET 
    total_spins = total_spins + 1,
    total_rewards = total_rewards + CASE 
      WHEN NEW.reward_type IN ('points', 'jackpot', 'token')
      THEN NEW.reward_value 
      ELSE 0 
    END
  WHERE id = NEW.user_id;

  -- 2. Handle extra spins reward
  IF NEW.reward_type = 'extra_spin' THEN
    UPDATE users
    SET spins_balance = spins_balance + NEW.reward_value
    WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update user stats
CREATE TRIGGER update_stats_after_spin
  AFTER INSERT ON spins
  FOR EACH ROW
  EXECUTE FUNCTION update_user_stats_after_spin();

