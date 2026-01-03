# SpinMaster Backend

> **Status**: ✅ RUNNING on `http://localhost:3000`

Secure backend API for SpinMaster game with Solana wallet authentication, JWT tokens, server-side game logic, and payment verification.

---

## 🚀 Quick Start (Already Running!)

Backend is currently running with:
- **Server**: `http://localhost:3000`
- **Database**: Supabase (Connected)
- **Network**: Solana Devnet

### Test It
```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"...","environment":"development"}
```

---

## Features

- ✅ Solana wallet signature authentication
- ✅ JWT access & refresh tokens
- ✅ Server-side spin result generation (anti-cheat)
- ✅ On-chain payment verification
- ✅ Rate limiting & anti-spam
- ✅ Supabase PostgreSQL database
- ✅ Railway deployment ready

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Blockchain**: Solana (Devnet/Mainnet)
- **Auth**: JWT + Solana wallet signatures
- **Security**: Helmet, CORS, Rate limiting

## Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run `database/schema.sql`
3. Copy your project URL and keys

### 3. Environment Variables

Copy `.env.example` to `.env` and fill in:

```bash
cp .env.example .env
```

Required variables:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (from Supabase settings)
- `JWT_SECRET` - Random secret for JWT tokens
- `JWT_REFRESH_SECRET` - Random secret for refresh tokens
- `TREASURY_WALLET` - Your Solana wallet for receiving payments
- `SOLANA_RPC_URL` - Solana RPC endpoint (devnet or mainnet)

### 4. Run Development Server

```bash
npm run dev
```

Server will start on `http://localhost:3000`

## API Endpoints

### Authentication

- `GET /api/auth/nonce?walletAddress=xxx` - Get nonce for signing
- `POST /api/auth/login` - Login with wallet signature
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout

### User

- `GET /api/user/profile` - Get user profile (auth required)
- `GET /api/user/spins` - Get spin balance (auth required)

### Spin

- `POST /api/spin/daily-claim` - Claim daily free spin (auth required, rate limited)
- `POST /api/spin/execute` - Execute spin (auth required, rate limited)
- `GET /api/spin/history` - Get spin history (auth required)

### Payment

- `GET /api/payment/packages` - Get available spin packages
- `POST /api/payment/purchase-spins` - Purchase spins (auth required, rate limited)

### Leaderboard

- `GET /api/leaderboard/:period` - Get leaderboard (period: daily/weekly/all-time)

## Authentication Flow

1. **Client**: Request nonce
   ```
   GET /api/auth/nonce?walletAddress=YOUR_WALLET
   ```

2. **Client**: Sign nonce with wallet
   ```javascript
   const signature = await wallet.signMessage(nonce);
   ```

3. **Client**: Login with signature
   ```
   POST /api/auth/login
   {
     "walletAddress": "YOUR_WALLET",
     "signature": "SIGNATURE"
   }
   ```

4. **Server**: Returns JWT tokens
   ```json
   {
     "accessToken": "...",
     "refreshToken": "...",
     "user": {...}
   }
   ```

5. **Client**: Use access token in headers
   ```
   Authorization: Bearer ACCESS_TOKEN
   ```

## Payment Verification Flow

1. **Client**: Send SOL to treasury wallet
2. **Client**: Submit transaction signature
   ```
   POST /api/payment/purchase-spins
   {
     "txSignature": "TX_SIGNATURE",
     "packageId": 10
   }
   ```

3. **Server**: Verify transaction on-chain
4. **Server**: Add spins to user balance

## 📱 Connect from Flutter App

### Android Emulator
```dart
final baseUrl = 'http://10.0.2.2:3000';
```

### iOS Simulator
```dart
final baseUrl = 'http://localhost:3000';
```

### Real Device (same WiFi)
```dart
final baseUrl = 'http://YOUR_COMPUTER_IP:3000';
// Find your IP: ifconfig (Mac) or ipconfig (Windows)
```

---

## Deployment to Railway

1. Create new project on [railway.app](https://railway.app)
2. Connect your GitHub repository
3. Add environment variables in Railway dashboard
4. Deploy!

Railway will automatically:
- Install dependencies
- Run `npm start`
- Provide a public URL

## Security Features

- **Wallet Signature Verification**: Prevents unauthorized access
- **Nonce with Timestamp**: Prevents replay attacks (5min expiry)
- **JWT Tokens**: Secure session management
- **Rate Limiting**: Prevents spam and abuse
- **On-chain Verification**: Prevents fake payments
- **Server-side RNG**: Prevents result manipulation
- **Input Validation**: Prevents injection attacks

## Rate Limits

- Daily claim: 1 per 24 hours per wallet
- Spin execution: 100 per hour per wallet
- Login: 5 attempts per 15 minutes per IP
- Payment: 10 purchases per hour per wallet
- Global: 1000 requests per hour per IP

## Development

```bash
# Install dependencies
npm install

# Run in development mode (with nodemon)
npm run dev

# Run in production mode
npm start
```

## License

MIT
