import { Router } from 'express';
import {
  getUploadUrl,
  createAnalysis,
  getHistory,
  getStats,
  deleteAnalysis,
} from '../controllers/analysis.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/upload-url', getUploadUrl);   // Step 1: get presigned URL to upload audio
router.post('/', createAnalysis);            // Step 2: save analysis record (with audioUrl from step 1)
router.get('/history', getHistory);
router.get('/stats', getStats);
router.delete('/:id', deleteAnalysis);

export default router;
