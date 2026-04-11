import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { OAuth2Client } from 'google-auth-library';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

// ─── Schemas ──────────────────────────────────────────────────────────────────

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required').max(100),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1, 'Password is required'),
});

const appleSchema = z.object({
  identityToken: z.string().min(1, 'identityToken is required'),
  name: z.string().max(100).optional(),
});

const googleSchema = z.object({
  idToken: z.string().min(1, 'idToken is required'),
  name: z.string().max(100).optional(),
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function signToken(userId: string): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET not set');
  return jwt.sign({ userId }, secret, { expiresIn: '30d' });
}

const APPLE_JWKS = createRemoteJWKSet(
  new URL('https://appleid.apple.com/auth/keys')
);

const googleClient = new OAuth2Client();

// ─── Email / Password ─────────────────────────────────────────────────────────

export async function register(req: Request, res: Response): Promise<void> {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { email, password, name } = parsed.data;

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    res.status(409).json({ error: 'Email already registered' });
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: { email, passwordHash, name },
    select: { id: true, email: true, name: true, createdAt: true },
  });

  res.status(201).json({ token: signToken(user.id), user });
}

export async function login(req: Request, res: Response): Promise<void> {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { email, password } = parsed.data;

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !user.passwordHash) {
    res.status(401).json({ error: 'Invalid credentials' });
    return;
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    res.status(401).json({ error: 'Invalid credentials' });
    return;
  }

  res.json({
    token: signToken(user.id),
    user: { id: user.id, email: user.email, name: user.name, createdAt: user.createdAt },
  });
}

// ─── Apple Sign In ────────────────────────────────────────────────────────────

export async function appleSignIn(req: Request, res: Response): Promise<void> {
  const parsed = appleSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { identityToken, name } = parsed.data;

  let appleId: string;
  let email: string | undefined;

  try {
    const { payload } = await jwtVerify(identityToken, APPLE_JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: process.env.APPLE_CLIENT_ID,
    });

    appleId = payload.sub as string;
    email = payload.email as string | undefined;
  } catch {
    res.status(401).json({ error: 'Invalid Apple identity token' });
    return;
  }

  // Find existing user by appleId, or by email, or create new
  let user = await prisma.user.findUnique({ where: { appleId } });

  if (!user && email) {
    user = await prisma.user.findUnique({ where: { email } });
    if (user) {
      user = await prisma.user.update({ where: { id: user.id }, data: { appleId } });
    }
  }

  if (!user) {
    user = await prisma.user.create({
      data: {
        appleId,
        email: email ?? null,
        name: name ?? email?.split('@')[0] ?? 'CryLens User',
      },
    });
  }

  res.json({
    token: signToken(user.id),
    user: { id: user.id, email: user.email, name: user.name, createdAt: user.createdAt },
  });
}

// ─── Google Sign In ───────────────────────────────────────────────────────────

export async function googleSignIn(req: Request, res: Response): Promise<void> {
  const parsed = googleSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { idToken } = parsed.data;

  let googleId: string;
  let email: string | undefined;
  let googleName: string | undefined;

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub) throw new Error('No sub in payload');

    googleId = payload.sub;
    email = payload.email;
    googleName = payload.name;
  } catch {
    res.status(401).json({ error: 'Invalid Google ID token' });
    return;
  }

  // Find existing user by googleId, or by email, or create new
  let user = await prisma.user.findUnique({ where: { googleId } });

  if (!user && email) {
    user = await prisma.user.findUnique({ where: { email } });
    if (user) {
      user = await prisma.user.update({ where: { id: user.id }, data: { googleId } });
    }
  }

  if (!user) {
    user = await prisma.user.create({
      data: {
        googleId,
        email: email ?? null,
        name: googleName ?? email?.split('@')[0] ?? 'CryLens User',
      },
    });
  }

  res.json({
    token: signToken(user.id),
    user: { id: user.id, email: user.email, name: user.name, createdAt: user.createdAt },
  });
}

// ─── Me ───────────────────────────────────────────────────────────────────────

export async function me(req: AuthRequest, res: Response): Promise<void> {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: { id: true, email: true, name: true, createdAt: true, updatedAt: true },
  });

  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }

  res.json({ user });
}
