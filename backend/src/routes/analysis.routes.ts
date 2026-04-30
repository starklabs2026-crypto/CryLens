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
import { asyncHandler } from '../middleware/asyncHandler';

const router = Router();

router.use(authenticate);

router.post('/upload-url', asyncHandler(getUploadUrl)); // Step 1: get presigned URL to upload audio
router.post('/analyze', asyncHandler(analyzeAudio)); // Step 2: AI-analyze uploaded audio -> save + return result
router.post('/', asyncHandler(createAnalysis)); // Manual: save analysis record without AI
router.get('/usage', asyncHandler(getUsage));
router.get('/history', asyncHandler(getHistory));
router.get('/stats', asyncHandler(getStats));
router.delete('/:id', asyncHandler(deleteAnalysis));

export default router;
