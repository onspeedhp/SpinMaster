import rateLimit from 'express-rate-limit';

// Daily claim rate limiter - 1 request per 24 hours per IP
export const dailyClaimLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 1,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Daily spin already claimed. Please try again tomorrow.'
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Use wallet address as key instead of IP
  keyGenerator: (req) => req.user?.walletAddress || req.ip
});

// Spin execution rate limiter - 100 spins per hour per user
export const spinLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 100,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many spin requests. Please try again later.'
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.walletAddress || req.ip
});

// Login rate limiter - 5 attempts per 15 minutes per IP
export const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many login attempts. Please try again later.'
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Payment rate limiter - 10 purchases per hour per user
export const paymentLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many purchase requests. Please try again later.'
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.walletAddress || req.ip
});
