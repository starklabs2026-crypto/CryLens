# CryLens Backend

Node.js + Express + Prisma + TypeScript API for the CryLens baby cry analyser.

---

## Quick Start

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Start a local PostgreSQL database

```bash
docker run --name crylens-pg \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=crylens \
  -p 5432:5432 \
  -d postgres:16
```

### 3. Configure environment

```bash
cp .env.example .env
# Edit .env — the default DATABASE_URL matches the docker command above
```

### 4. Run migrations and generate client

```bash
npm run db:migrate   # creates tables
npm run db:generate  # regenerates Prisma client (run after schema changes)
```

### 5. Seed demo data

```bash
npm run db:seed
# Creates: demo@crylens.app / password123, Baby Alex, 10 cry analyses
```

### 6. Start the dev server

```bash
npm run dev
# Server starts at http://localhost:3000
```

---

## Available Scripts

| Script | Description |
|---|---|
| `npm run dev` | Start with hot-reload via nodemon |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm run start` | Run compiled `dist/server.js` |
| `npm run db:migrate` | Apply pending migrations (dev) |
| `npm run db:generate` | Regenerate Prisma client after schema change |
| `npm run db:studio` | Open Prisma Studio at http://localhost:5555 |
| `npm run db:seed` | Seed demo data |
| `npm test` | Run Jest test suite |
| `npm run lint` | TypeScript type-check (no emit) |

---

## Prisma Studio

Inspect and edit data via a visual browser UI:

```bash
npm run db:studio
# Opens http://localhost:5555
```

---

## API Reference — curl Examples

> Replace `TOKEN` with the JWT returned from login/register.

### Auth

```bash
# Register
curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"password123","name":"Your Name"}' | jq

# Login
curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"password123"}' | jq

# Me (requires auth)
curl -s http://localhost:3000/auth/me \
  -H "Authorization: Bearer TOKEN" | jq
```

### Babies

```bash
# List babies
curl -s http://localhost:3000/babies \
  -H "Authorization: Bearer TOKEN" | jq

# Create baby
curl -s -X POST http://localhost:3000/babies \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Baby Alex","dob":"2024-01-15"}' | jq

# Update baby (replace BABY_ID)
curl -s -X PUT http://localhost:3000/babies/BABY_ID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alex"}' | jq

# Delete baby
curl -s -X DELETE http://localhost:3000/babies/BABY_ID \
  -H "Authorization: Bearer TOKEN"
```

### Cry Analysis

```bash
# Create analysis (replace BABY_ID)
curl -s -X POST http://localhost:3000/analysis \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"babyId":"BABY_ID","label":"hungry","confidence":0.87,"durationSec":30,"notes":"Before 10am feed"}' | jq

# Get history (paginated)
curl -s "http://localhost:3000/analysis/history?page=1&limit=10" \
  -H "Authorization: Bearer TOKEN" | jq

# Get history filtered by baby
curl -s "http://localhost:3000/analysis/history?babyId=BABY_ID" \
  -H "Authorization: Bearer TOKEN" | jq

# Get stats (last 30 days)
curl -s "http://localhost:3000/analysis/stats?periodDays=30" \
  -H "Authorization: Bearer TOKEN" | jq

# Get stats filtered by baby
curl -s "http://localhost:3000/analysis/stats?babyId=BABY_ID&periodDays=7" \
  -H "Authorization: Bearer TOKEN" | jq

# Delete analysis (replace ANALYSIS_ID)
curl -s -X DELETE http://localhost:3000/analysis/ANALYSIS_ID \
  -H "Authorization: Bearer TOKEN"
```

### Health check

```bash
curl -s http://localhost:3000/health | jq
```

---

## Docker

Build and run with Docker (requires `DATABASE_URL` and `JWT_SECRET` set):

```bash
docker build -t crylens-backend .
docker run -p 3000:3000 \
  -e DATABASE_URL="postgresql://postgres:secret@host.docker.internal:5432/crylens?schema=public" \
  -e JWT_SECRET="your-secret" \
  -e NODE_ENV=production \
  crylens-backend
```

---

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma     # Database schema
│   └── seed.ts           # Demo data seeder
├── src/
│   ├── __tests__/        # Jest + supertest integration tests
│   ├── controllers/      # Route handler logic
│   ├── lib/              # Shared utilities (Prisma client)
│   ├── middleware/        # Auth middleware
│   ├── routes/           # Express routers
│   ├── app.ts            # Express app setup
│   └── server.ts         # HTTP server entrypoint
├── .env.example
├── Dockerfile
├── jest.config.js
├── package.json
└── tsconfig.json
```
