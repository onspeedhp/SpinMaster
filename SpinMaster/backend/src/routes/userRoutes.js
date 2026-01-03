import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { getProfile, getSpinsBalance } from '../controllers/userController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// GET /api/user/profile
router.get('/profile', getProfile);

// GET /api/user/spins
router.get('/spins', getSpinsBalance);

export default router;
