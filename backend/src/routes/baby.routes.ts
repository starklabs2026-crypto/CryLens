import { Router } from 'express';
import { getBabies, createBaby, updateBaby, deleteBaby } from '../controllers/baby.controller';
import { authenticate } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/asyncHandler';

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(getBabies));
router.post('/', asyncHandler(createBaby));
router.put('/:id', asyncHandler(updateBaby));
router.delete('/:id', asyncHandler(deleteBaby));

export default router;
