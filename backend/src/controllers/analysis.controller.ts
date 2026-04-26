import { Response } from 'express';
import { z } from 'zod';
import { CryLabel } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { getSupabase, isSupabaseConfigured, AUDIO_BUCKET } from '../lib/supabase';
import { AuthRequest } from '../middleware/auth.middleware';
import { analyzeCryAudio } from '../services/cryAnalyzer.service';

const CRY_LABELS = ['hungry', 'tired', 'pain', 'burping', 'discomfort'] as const;
const FREE_ANALYSIS_LIMIT = 5;

const createAnalysisSchema = z.object({
  babyId: z.string().uuid('babyId must be a UUID'),
  label: z.enum(CRY_LABELS, { errorMap: () => ({ message: 'Invalid cry label' }) }),
  confidence: z.number().min(0).max(1),
  durationSec: z.number().int().positive(),
  notes: z.string().max(500).optional(),
  audioUrl: z.string().max(1000).optional(),
});

const uploadUrlSchema = z.object({
  babyId: z.string().uuid('babyId must be a UUID'),
  fileName: z.string().min(1).max(200),
  mimeType: z.enum(['audio/m4a', 'audio/wav', 'audio/mp4', 'audio/mpeg', 'audio/ogg', 'audio/webm', 'audio/aac']),
});

export async function getUploadUrl(req: AuthRequest, res: Response): Promise<void> {
  if (!isSupabaseConfigured()) {
    res.status(503).json({ error: 'Audio upload unavailable', detail: 'Supabase storage is not configured' });
    return;
  }

  const parsed = uploadUrlSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { babyId, fileName } = parsed.data;
  const baby = await prisma.baby.findUnique({ where: { id: babyId } });
  if (!baby || baby.userId !== req.userId) {
    res.status(404).json({ error: 'Baby not found' });
    return;
  }

  const path = `${req.userId}/${babyId}/${Date.now()}-${fileName}`;
  const { data, error } = await getSupabase().storage.from(AUDIO_BUCKET).createSignedUploadUrl(path);

  if (error || !data) {
    res.status(500).json({ error: 'Failed to generate upload URL' });
    return;
  }

  res.json({
    uploadUrl: data.signedUrl,
    path,
    token: data.token,
  });
}

export async function createAnalysis(req: AuthRequest, res: Response): Promise<void> {
  const parsed = createAnalysisSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { babyId, label, confidence, durationSec, notes, audioUrl } = parsed.data;
  const baby = await prisma.baby.findUnique({ where: { id: babyId } });
  if (!baby || baby.userId !== req.userId) {
    res.status(404).json({ error: 'Baby not found' });
    return;
  }

  const analysis = await prisma.$transaction(async (tx) => {
    const created = await tx.cryAnalysis.create({
      data: { babyId, label: label as CryLabel, confidence, durationSec, notes, audioUrl },
    });

    await tx.$executeRaw`
      UPDATE "User"
      SET "freeAnalysesUsed" = COALESCE("freeAnalysesUsed", 0) + 1
      WHERE "id" = CAST(${req.userId} AS UUID)
    `;

    return created;
  });

  res.status(201).json({ analysis });
}

export async function getUsage(req: AuthRequest, res: Response): Promise<void> {
  const rows = await prisma.$queryRaw<Array<{ freeAnalysesUsed: number | null }>>`
    SELECT COALESCE("freeAnalysesUsed", 0) AS "freeAnalysesUsed"
    FROM "User"
    WHERE "id" = CAST(${req.userId} AS UUID)
    LIMIT 1
  `;

  const user = rows[0];
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }

  const freeAnalysesUsed = user.freeAnalysesUsed ?? 0;

  res.json({
    freeAnalysesUsed,
    freeAnalysisLimit: FREE_ANALYSIS_LIMIT,
    remainingFreeAnalyses: Math.max(0, FREE_ANALYSIS_LIMIT - freeAnalysesUsed),
  });
}

export async function getHistory(req: AuthRequest, res: Response): Promise<void> {
  const page = Math.max(1, parseInt(String(req.query.page ?? '1'), 10));
  const limit = Math.min(100, Math.max(1, parseInt(String(req.query.limit ?? '20'), 10)));
  const babyId = req.query.babyId as string | undefined;

  if (babyId) {
    const baby = await prisma.baby.findUnique({ where: { id: babyId } });
    if (!baby || baby.userId !== req.userId) {
      res.status(404).json({ error: 'Baby not found' });
      return;
    }
  }

  const where = babyId ? { babyId } : { baby: { userId: req.userId } };

  const [total, analyses] = await Promise.all([
    prisma.cryAnalysis.count({ where }),
    prisma.cryAnalysis.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      include: { baby: { select: { id: true, name: true } } },
    }),
  ]);

  const data = await Promise.all(
    analyses.map(async (analysis) => {
      if (!analysis.audioUrl || !isSupabaseConfigured()) return analysis;
      const { data: signed } = await getSupabase().storage
        .from(AUDIO_BUCKET)
        .createSignedUrl(analysis.audioUrl, 3600);
      return { ...analysis, audioSignedUrl: signed?.signedUrl ?? null };
    }),
  );

  res.json({
    data,
    meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
  });
}

export async function getStats(req: AuthRequest, res: Response): Promise<void> {
  const babyId = req.query.babyId as string | undefined;
  const parsedPeriodDays = parseInt(String(req.query.periodDays ?? '30'), 10);
  const periodDays = Number.isNaN(parsedPeriodDays) ? 30 : Math.max(0, parsedPeriodDays);

  if (babyId) {
    const baby = await prisma.baby.findUnique({ where: { id: babyId } });
    if (!baby || baby.userId !== req.userId) {
      res.status(404).json({ error: 'Baby not found' });
      return;
    }
  }

  const since = new Date();
  since.setDate(since.getDate() - periodDays);

  const where = babyId
    ? { babyId, createdAt: { gte: since } }
    : { baby: { userId: req.userId }, createdAt: { gte: since } };

  const analyses = await prisma.cryAnalysis.findMany({
    where,
    select: { label: true, confidence: true },
  });

  if (analyses.length === 0) {
    res.json({ breakdown: {}, topLabel: null, avgConfidence: 0, totalAnalyses: 0, periodDays });
    return;
  }

  const breakdown: Record<string, number> = {};
  let totalConfidence = 0;

  for (const analysis of analyses) {
    breakdown[analysis.label] = (breakdown[analysis.label] ?? 0) + 1;
    totalConfidence += analysis.confidence;
  }

  const topLabel = Object.entries(breakdown).sort((a, b) => b[1] - a[1])[0][0];
  const avgConfidence = parseFloat((totalConfidence / analyses.length).toFixed(4));

  res.json({ breakdown, topLabel, avgConfidence, totalAnalyses: analyses.length, periodDays });
}

const analyzeSchema = z.object({
  babyId: z.string().uuid('babyId must be a UUID'),
  audioPath: z.string().min(1, 'audioPath is required'),
  durationSec: z.number().int().positive(),
});

export async function analyzeAudio(req: AuthRequest, res: Response): Promise<void> {
  const parsed = analyzeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed', issues: parsed.error.flatten().fieldErrors });
    return;
  }

  const { babyId, audioPath, durationSec } = parsed.data;
  const baby = await prisma.baby.findUnique({ where: { id: babyId } });
  if (!baby || baby.userId !== req.userId) {
    res.status(404).json({ error: 'Baby not found' });
    return;
  }

  if (!isSupabaseConfigured()) {
    res.status(503).json({ error: 'Audio analysis unavailable', detail: 'Supabase storage is not configured' });
    return;
  }

  if (!process.env.OPENAI_API_KEY?.trim()) {
    res.status(503).json({ error: 'AI analysis unavailable', detail: 'OPENAI_API_KEY is not configured' });
    return;
  }

  let result;
  try {
    result = await analyzeCryAudio(audioPath, durationSec);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Analysis failed';
    res.status(502).json({ error: 'AI analysis failed', detail: message });
    return;
  }

  const analysis = await prisma.$transaction(async (tx) => {
    const created = await tx.cryAnalysis.create({
      data: {
        babyId,
        label: result.label as CryLabel,
        confidence: result.confidence,
        durationSec,
        notes: result.notes,
        audioUrl: audioPath,
      },
    });

    await tx.$executeRaw`
      UPDATE "User"
      SET "freeAnalysesUsed" = COALESCE("freeAnalysesUsed", 0) + 1
      WHERE "id" = CAST(${req.userId} AS UUID)
    `;

    return created;
  });

  res.status(201).json({ analysis, aiResult: result });
}

export async function deleteAnalysis(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;
  const analysis = await prisma.cryAnalysis.findUnique({
    where: { id },
    include: { baby: { select: { userId: true } } },
  });

  if (!analysis || analysis.baby.userId !== req.userId) {
    res.status(404).json({ error: 'Analysis not found' });
    return;
  }

  if (analysis.audioUrl && isSupabaseConfigured()) {
    await getSupabase().storage.from(AUDIO_BUCKET).remove([analysis.audioUrl]);
  }

  await prisma.cryAnalysis.delete({ where: { id } });
  res.status(204).send();
}
