-- CreateEnum
CREATE TYPE "CryLabel" AS ENUM ('hungry', 'tired', 'pain', 'burping', 'discomfort');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "email" TEXT,
    "passwordHash" TEXT,
    "name" TEXT NOT NULL,
    "appleId" TEXT,
    "googleId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Baby" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "dob" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "Baby_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CryAnalysis" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "babyId" UUID NOT NULL,
    "label" "CryLabel" NOT NULL,
    "confidence" DOUBLE PRECISION NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "notes" TEXT,
    "audioUrl" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "CryAnalysis_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX "User_appleId_key" ON "User"("appleId");
CREATE UNIQUE INDEX "User_googleId_key" ON "User"("googleId");
CREATE INDEX "idx_user_email" ON "User"("email");
CREATE INDEX "idx_user_apple" ON "User"("appleId");
CREATE INDEX "idx_user_google" ON "User"("googleId");
CREATE INDEX "idx_baby_userid" ON "Baby"("userId");
CREATE INDEX "idx_analysis_babyid" ON "CryAnalysis"("babyId");
CREATE INDEX "idx_analysis_createdat" ON "CryAnalysis"("createdAt");

-- AddForeignKey
ALTER TABLE "Baby" ADD CONSTRAINT "Baby_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CryAnalysis" ADD CONSTRAINT "CryAnalysis_babyId_fkey"
    FOREIGN KEY ("babyId") REFERENCES "Baby"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Trigger for updatedAt
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_updated_at
  BEFORE UPDATE ON "User"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
