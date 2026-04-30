import { Router } from 'express';
import { register, login, appleSignIn, googleSignIn, me, deleteMe } from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/asyncHandler';

const router = Router();

// Email / password (kept for testing and web clients)
router.post('/register', asyncHandler(register));
router.post('/login', asyncHandler(login));

// OAuth — iOS clients send the token obtained from Apple/Google SDK
router.post('/apple', asyncHandler(appleSignIn));
router.post('/google', asyncHandler(googleSignIn));

// Authenticated
router.get('/me', authenticate, asyncHandler(me));
router.delete('/me', authenticate, asyncHandler(deleteMe));

export default router;
