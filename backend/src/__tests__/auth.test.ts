import request from 'supertest';
import app from '../app';
import { prisma } from '../lib/prisma';

const TEST_EMAIL = `test-auth-${Date.now()}@crylens.test`;
const TEST_PASSWORD = 'password123';
const TEST_NAME = 'Test User';

let authToken: string;

afterAll(async () => {
  await prisma.user.deleteMany({ where: { email: { endsWith: '@crylens.test' } } });
  await prisma.$disconnect();
});

describe('POST /auth/register', () => {
  it('registers a new user and returns a token', async () => {
    const res = await request(app).post('/auth/register').send({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      name: TEST_NAME,
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.email).toBe(TEST_EMAIL);
    authToken = res.body.token as string;
  });

  it('rejects duplicate email', async () => {
    const res = await request(app).post('/auth/register').send({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      name: TEST_NAME,
    });

    expect(res.status).toBe(409);
    expect(res.body).toHaveProperty('error');
  });

  it('rejects invalid email format', async () => {
    const res = await request(app).post('/auth/register').send({
      email: 'not-an-email',
      password: TEST_PASSWORD,
      name: TEST_NAME,
    });

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('issues');
  });

  it('rejects password shorter than 8 characters', async () => {
    const res = await request(app).post('/auth/register').send({
      email: `short-pw-${Date.now()}@crylens.test`,
      password: 'abc',
      name: TEST_NAME,
    });

    expect(res.status).toBe(400);
  });
});

describe('POST /auth/login', () => {
  it('logs in with valid credentials', async () => {
    const res = await request(app).post('/auth/login').send({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    authToken = res.body.token as string;
  });

  it('rejects wrong password', async () => {
    const res = await request(app).post('/auth/login').send({
      email: TEST_EMAIL,
      password: 'wrongpassword',
    });

    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  it('rejects unknown email', async () => {
    const res = await request(app).post('/auth/login').send({
      email: 'nobody@crylens.test',
      password: TEST_PASSWORD,
    });

    expect(res.status).toBe(401);
  });

  it('rejects missing fields', async () => {
    const res = await request(app).post('/auth/login').send({ email: TEST_EMAIL });

    expect(res.status).toBe(400);
  });
});

describe('GET /auth/me', () => {
  it('returns the authenticated user', async () => {
    const res = await request(app)
      .get('/auth/me')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe(TEST_EMAIL);
  });

  it('rejects missing token', async () => {
    const res = await request(app).get('/auth/me');

    expect(res.status).toBe(401);
  });

  it('rejects invalid token', async () => {
    const res = await request(app)
      .get('/auth/me')
      .set('Authorization', 'Bearer invalid.token.value');

    expect(res.status).toBe(401);
  });
});
