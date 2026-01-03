import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { paymentLimiter } from '../middleware/rateLimiter.js';
import { getPackages, purchaseSpins } from '../controllers/paymentController.js';

const router = express.Router();

// GET /api/payment/packages (public)
router.get('/packages', getPackages);

// POST /api/payment/purchase-spins (authenticated + rate limited)
router.post('/purchase-spins', authenticateToken, paymentLimiter, purchaseSpins);

export default router;
