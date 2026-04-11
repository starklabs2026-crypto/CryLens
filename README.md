# CryLens

AI-powered baby cry analyser — classifies infant cries into categories (hungry, tired, pain, burping, discomfort) using machine learning, with a history dashboard and per-baby analytics.

---

## Architecture

```
CryLens/
├── backend/    Node.js + Express + Prisma + TypeScript API (fully cross-platform)
├── ios/        SwiftUI iOS frontend (requires Xcode on macOS)
├── docs/       Architecture and API documentation
└── .github/    GitHub Actions CI/CD workflows
```

The **backend** runs on any platform (macOS, Linux, Windows, Docker). You can develop and test the full API without macOS or Xcode.

The **iOS frontend** requires Xcode on macOS. See `ios/README.md` for details.

---

## Getting Started — Backend

> Full instructions are in [backend/README.md](./backend/README.md).

```bash
# 1. Start a Postgres database
docker run --name crylens-pg \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=crylens \
  -p 5432:5432 -d postgres:16

# 2. Install and configure
cd backend
npm install
cp .env.example .env   # edit DATABASE_URL if needed

# 3. Migrate + seed
npm run db:migrate
npm run db:seed

# 4. Start
npm run dev            # http://localhost:3000
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| API runtime | Node.js 20 + Express 4 |
| Language | TypeScript 5 (strict mode) |
| ORM | Prisma 5 |
| Database | PostgreSQL 16 |
| Auth | JWT (jsonwebtoken) + bcryptjs |
| Validation | Zod |
| Security | Helmet + CORS |
| Testing | Jest + ts-jest + Supertest |
| CI/CD | GitHub Actions + Railway |
| iOS | SwiftUI (requires macOS + Xcode) |

---

## Roadmap

- [x] User auth (register, login, JWT)
- [x] Baby management (CRUD, ownership checks)
- [x] Cry analysis (create, history, stats, delete)
- [x] Pagination and filtering on history endpoint
- [x] Per-label breakdown stats with configurable period
- [x] GitHub Actions CI (lint + typecheck + test + deploy)
- [ ] ML model integration (audio classification)
- [ ] iOS SwiftUI frontend
- [ ] Push notifications for cry detection
- [ ] Multi-caretaker support per baby

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit and push
4. Open a pull request against `develop`

All PRs must pass the CI pipeline (lint + typecheck + tests) before merging.
