import express from 'express';
import { getNonce, login, refresh, logout } from '../controllers/authController.js';

const router = express.Router();

// GET /api/auth/nonce?walletAddress=xxx
router.get('/nonce', getNonce);

// POST /api/auth/login
router.post('/login', login);

// POST /api/auth/refresh
router.post('/refresh', refresh);

// POST /api/auth/logout
router.post('/logout', logout);

export default router;
