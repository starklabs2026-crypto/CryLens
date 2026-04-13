import request from 'supertest';
import app from '../app';
import { prisma } from '../lib/prisma';

const UNIQUE = Date.now();
const USER_EMAIL = `test-analysis-${UNIQUE}@crylens.test`;
const USER_PASSWORD = 'password123';

let authToken: string;
let babyId: string;
let analysisId: string;

beforeAll(async () => {
  const regRes = await request(app).post('/auth/register').send({
    email: USER_EMAIL,
    password: USER_PASSWORD,
    name: 'Analysis Tester',
  });
  authToken = regRes.body.token as string;

  const babyRes = await request(app)
    .post('/babies')
    .set('Authorization', `Bearer ${authToken}`)
    .send({ name: 'Test Baby', dob: '2024-03-01' });
  babyId = babyRes.body.baby.id as string;
});

afterAll(async () => {
  await prisma.user.deleteMany({ where: { email: { endsWith: '@crylens.test' } } });
  await prisma.$disconnect();
});

describe('POST /analysis', () => {
  it('creates a valid cry analysis', async () => {
    const res = await request(app)
      .post('/analysis')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        babyId,
        label: 'hungry',
        confidence: 0.87,
        durationSec: 30,
        notes: 'Cried before feed',
      });

    expect(res.status).toBe(201);
    expect(res.body.analysis).toMatchObject({
      babyId,
      label: 'hungry',
      confidence: 0.87,
    });
    analysisId = res.body.analysis.id as string;
  });

  it('rejects invalid label', async () => {
    const res = await request(app)
      .post('/analysis')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ babyId, label: 'sleepy', confidence: 0.5, durationSec: 10 });

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('issues');
  });

  it('rejects confidence out of range', async () => {
    const res = await request(app)
      .post('/analysis')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ babyId, label: 'tired', confidence: 1.5, durationSec: 10 });

    expect(res.status).toBe(400);
  });

  it('rejects unknown babyId', async () => {
    const res = await request(app)
      .post('/analysis')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        babyId: '00000000-0000-0000-0000-000000000000',
        label: 'tired',
        confidence: 0.7,
        durationSec: 15,
      });

    expect(res.status).toBe(404);
  });

  it('requires authentication', async () => {
    const res = await request(app)
      .post('/analysis')
      .send({ babyId, label: 'tired', confidence: 0.7, durationSec: 15 });

    expect(res.status).toBe(401);
  });
});

describe('GET /analysis/history', () => {
  it('returns paginated history', async () => {
    const res = await request(app)
      .get('/analysis/history')
      .set('Authorization', `Bearer ${authToken}`)
      .query({ page: 1, limit: 10 });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(res.body).toHaveProperty('meta');
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('filters by babyId', async () => {
    const res = await request(app)
      .get('/analysis/history')
      .set('Authorization', `Bearer ${authToken}`)
      .query({ babyId });

    expect(res.status).toBe(200);
    const ids: string[] = res.body.data.map((a: { babyId: string }) => a.babyId);
    expect(ids.every((id) => id === babyId)).toBe(true);
  });

  it('rejects unauthenticated request', async () => {
    const res = await request(app).get('/analysis/history');

    expect(res.status).toBe(401);
  });
});

describe('GET /analysis/stats', () => {
  it('returns stats for the user', async () => {
    const res = await request(app)
      .get('/analysis/stats')
      .set('Authorization', `Bearer ${authToken}`)
      .query({ periodDays: 30 });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('breakdown');
    expect(res.body).toHaveProperty('topLabel');
    expect(res.body).toHaveProperty('avgConfidence');
    expect(res.body).toHaveProperty('totalAnalyses');
  });

  it('returns zero stats when no analyses exist in period', async () => {
    const res = await request(app)
      .get('/analysis/stats')
      .set('Authorization', `Bearer ${authToken}`)
      .query({ periodDays: 0 });

    expect(res.status).toBe(200);
    expect(res.body.totalAnalyses).toBe(0);
  });
});

describe('DELETE /analysis/:id', () => {
  it('deletes an existing analysis', async () => {
    const res = await request(app)
      .delete(`/analysis/${analysisId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(204);
  });

  it('returns 404 for already deleted analysis', async () => {
    const res = await request(app)
      .delete(`/analysis/${analysisId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(404);
  });

  it('rejects unauthenticated delete', async () => {
    const res = await request(app).delete(`/analysis/${analysisId}`);

    expect(res.status).toBe(401);
  });
});
