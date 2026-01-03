import express from 'express';
import { getLeaderboard } from '../controllers/leaderboardController.js';

const router = express.Router();

// GET /api/leaderboard/:period (public)
// period can be: daily, weekly, all-time
router.get('/:period', getLeaderboard);

export default router;
