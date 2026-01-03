import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { dailyClaimLimiter, spinLimiter } from '../middleware/rateLimiter.js';
import { claimDailySpin, executeSpin, getSpinHistory, getWheelConfig } from '../controllers/spinController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// GET /api/spin/configuration
router.get('/configuration', getWheelConfig);

// POST /api/spin/daily-claim (rate limited: 1 per 24h)
router.post('/daily-claim', dailyClaimLimiter, claimDailySpin);

// POST /api/spin/execute (rate limited: 100 per hour)
router.post('/execute', spinLimiter, executeSpin);

// GET /api/spin/history
router.get('/history', getSpinHistory);

export default router;
