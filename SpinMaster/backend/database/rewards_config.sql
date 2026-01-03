-- Dynamic rewards configuration table
CREATE TABLE rewards_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  segment_index INTEGER UNIQUE NOT NULL,
  reward_type TEXT NOT NULL CHECK (reward_type IN ('points', 'extra_spin', 'jackpot', 'token', 'none')),
  reward_value NUMERIC(20, 8) NOT NULL,
  symbol TEXT,
  label TEXT NOT NULL,
  weight NUMERIC(10, 2) NOT NULL,
  color_hex TEXT NOT NULL,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed with enhanced official wheel config (8 segments with Token Icons)
-- Colors and Icons for SOL, USDC, USDT, SEEK
INSERT INTO rewards_config (segment_index, reward_type, reward_value, symbol, label, weight, color_hex, icon_url) VALUES
(0, 'token', 0.1, 'SOL', '0.1 SOL', 10, '#E040FB', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png'),
(1, 'none', 0, NULL, 'Better Luck!', 25, '#9E9E9E', NULL),
(2, 'token', 10, 'USDC', '10 USDC', 15, '#2196F3', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png'),
(3, 'extra_spin', 1, NULL, 'Bonus 1 Spin', 12, '#4CAF50', NULL),
(4, 'token', 999, 'USDT', '999 USDT 🔥', 0.5, '#009688', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB/logo.png'),
(5, 'token', 100, 'SEEK', '100 SEEK', 20, '#FFC107', 'https://cdn-icons-png.flaticon.com/512/2535/2535072.png'),
(6, 'extra_spin', 2, NULL, 'Bonus 2 Spins', 5, '#00C853', NULL),
(7, 'none', 0, NULL, 'Try Higher!', 12.5, '#FF5252', NULL);
