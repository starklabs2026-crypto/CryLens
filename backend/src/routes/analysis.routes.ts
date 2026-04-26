import { Router } from 'express';
import {
  getUploadUrl,
  analyzeAudio,
  createAnalysis,
  getHistory,
  getStats,
  getUsage,
  deleteAnalysis,
} from '../controllers/analysis.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/upload-url', getUploadUrl);   // Step 1: get presigned URL to upload audio
router.post('/analyze', analyzeAudio);      // Step 2: AI-analyze uploaded audio → save + return result
router.post('/', createAnalysis);            // Manual: save analysis record without AI
router.get('/usage', getUsage);
router.get('/history', getHistory);
router.get('/stats', getStats);
router.delete('/:id', deleteAnalysis);

export default router;
