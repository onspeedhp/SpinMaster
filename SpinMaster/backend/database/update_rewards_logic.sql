-- Update spins table to include token symbol
ALTER TABLE spins ADD COLUMN symbol TEXT;

-- Clear existing rewards configuration to reset with new logic
TRUNCATE TABLE rewards_config;

-- Insert new segments (12 segments with 3 types: token, extra_spin, none)
-- More 'none' options as requested
INSERT INTO rewards_config (segment_index, reward_type, reward_value, symbol, label, weight, color_hex, icon_url) VALUES
(0, 'token', 0.05, 'SOL', '0.05 SOL', 5, '#E040FB', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png'),
(1, 'none', 0, NULL, 'Good Luck!', 20, '#757575', NULL),
(2, 'token', 5, 'USDC', '5 USDC', 10, '#2196F3', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png'),
(3, 'none', 0, NULL, 'Try Again', 20, '#616161', NULL),
(4, 'extra_spin', 1, NULL, '1 Free Spin', 15, '#4CAF50', NULL),
(5, 'none', 0, NULL, 'So Close!', 20, '#757575', NULL),
(6, 'token', 50, 'SEEK', '50 SEEK', 15, '#FFC107', 'https://cdn-icons-png.flaticon.com/512/2535/2535072.png'),
(7, 'none', 0, NULL, 'Missed It', 20, '#616161', NULL),
(8, 'token', 1, 'USDT', '1 USDT', 8, '#009688', 'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB/logo.png'),
(9, 'none', 0, NULL, 'Not Today', 20, '#757575', NULL),
(10, 'extra_spin', 3, NULL, '3 Free Spins', 2, '#00C853', NULL),
(11, 'none', 0, NULL, 'Spin Again', 20, '#616161', NULL);

-- Update check constraints (Optional but recommended for consistency)
-- Note: PostgreSQL doesn't allow altering CHECK constraints directly easily without dropping and re-adding.
-- We assumes strict mode isn't required immediately, but for documentation:
-- The app logic will now only enforce 'token', 'extra_spin', 'none' via the config above.

-- Create/Update trigger to include symbol handling if needed?
-- The existing trigger update_user_stats_after_spin handles total_rewards numeric addition.
-- For token balances, we might ideally need a 'wallets' or 'balances' table, but sticking to 'total_rewards' for now as per minimal change request.
