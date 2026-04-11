import { Router } from 'express';
import {
  createAnalysis,
  getHistory,
  getStats,
  deleteAnalysis,
} from '../controllers/analysis.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/', createAnalysis);
router.get('/history', getHistory);
router.get('/stats', getStats);
router.delete('/:id', deleteAnalysis);

export default router;
