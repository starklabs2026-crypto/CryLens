import { PrismaClient, CryLabel } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const labels: CryLabel[] = ['hungry', 'tired', 'pain', 'burping', 'discomfort'];

function randomLabel(): CryLabel {
  return labels[Math.floor(Math.random() * labels.length)];
}

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

async function main(): Promise<void> {
  console.log('Seeding database...');

  await prisma.cryAnalysis.deleteMany();
  await prisma.baby.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('password123', 10);

  const user = await prisma.user.create({
    data: {
      email: 'demo@crylens.app',
      passwordHash,
      name: 'Demo User',
    },
  });
  console.log(`Created user: ${user.email}`);

  const baby = await prisma.baby.create({
    data: {
      userId: user.id,
      name: 'Baby Alex',
      dob: new Date('2024-01-15'),
    },
  });
  console.log(`Created baby: ${baby.name}`);

  const analyses = [];
  for (let i = 0; i < 10; i++) {
    analyses.push({
      babyId: baby.id,
      label: randomLabel(),
      confidence: parseFloat((0.65 + Math.random() * 0.30).toFixed(2)),
      durationSec: Math.floor(10 + Math.random() * 50),
      notes: i % 3 === 0 ? `Auto-note #${i + 1}` : null,
      createdAt: daysAgo(i),
    });
  }

  await prisma.cryAnalysis.createMany({ data: analyses });
  console.log(`Created ${analyses.length} cry analyses`);

  console.log('Seeding complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
