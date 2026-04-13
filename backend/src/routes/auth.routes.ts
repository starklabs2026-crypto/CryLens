import { Router } from 'express';
import { register, login, appleSignIn, googleSignIn, me, deleteMe } from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Email / password (kept for testing and web clients)
router.post('/register', register);
router.post('/login', login);

// OAuth — iOS clients send the token obtained from Apple/Google SDK
router.post('/apple', appleSignIn);
router.post('/google', googleSignIn);

// Authenticated
router.get('/me', authenticate, me);
router.delete('/me', authenticate, deleteMe);

export default router;
