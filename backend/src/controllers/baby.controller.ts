import { Response } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

const createBabySchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  dob: z.string().refine((v) => !isNaN(Date.parse(v)), { message: 'Invalid date of birth' }),
});

const updateBabySchema = z.object({
  name: z.string().min(1).max(100).optional(),
  dob: z
    .string()
    .refine((v) => !isNaN(Date.parse(v)), { message: 'Invalid date of birth' })
    .optional(),
});

export async function getBabies(req: AuthRequest, res: Response): Promise<void> {
  const babies = await prisma.baby.findMany({
    where: { userId: req.userId },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ babies });
}

export async function createBaby(req: AuthRequest, res: Response): Promise<void> {
  const parsed = createBabySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { name, dob } = parsed.data;

  const baby = await prisma.baby.create({
    data: {
      userId: req.userId as string,
      name,
      dob: new Date(dob),
    },
  });

  res.status(201).json({ baby });
}

export async function updateBaby(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;

  const existing = await prisma.baby.findUnique({ where: { id } });
  if (!existing || existing.userId !== req.userId) {
    res.status(404).json({ error: 'Baby not found' });
    return;
  }

  const parsed = updateBabySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const data: { name?: string; dob?: Date } = {};
  if (parsed.data.name !== undefined) data.name = parsed.data.name;
  if (parsed.data.dob !== undefined) data.dob = new Date(parsed.data.dob);

  const baby = await prisma.baby.update({ where: { id }, data });
  res.json({ baby });
}

export async function deleteBaby(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;

  const existing = await prisma.baby.findUnique({ where: { id } });
  if (!existing || existing.userId !== req.userId) {
    res.status(404).json({ error: 'Baby not found' });
    return;
  }

  await prisma.baby.delete({ where: { id } });
  res.status(204).send();
}
