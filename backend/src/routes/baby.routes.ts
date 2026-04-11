import { Router } from 'express';
import { getBabies, createBaby, updateBaby, deleteBaby } from '../controllers/baby.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/', getBabies);
router.post('/', createBaby);
router.put('/:id', updateBaby);
router.delete('/:id', deleteBaby);

export default router;
