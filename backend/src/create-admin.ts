// Creates or updates an admin account from backend/admin-credentials.env.
// Usage: edit that file, then run `npm run create-admin` in backend/.
import dotenv from 'dotenv';
import path from 'path';
import { PrismaClient } from '@prisma/client';
import { hashPassword } from './password';

dotenv.config();
// Credentials file the owner edits (backend/admin-credentials.env).
dotenv.config({ path: path.join(__dirname, '..', 'admin-credentials.env') });

const PLACEHOLDER_EMAIL = 'you@example.com';
const PLACEHOLDER_PASSWORD = 'change-me-min-8-chars';

async function main() {
  const email = (process.env.ADMIN_EMAIL || '').toLowerCase().trim();
  const password = process.env.ADMIN_PASSWORD || '';
  if (!email || password.length < 8) {
    throw new Error('Set ADMIN_EMAIL and an ADMIN_PASSWORD of at least 8 characters in backend/admin-credentials.env.');
  }
  if (email === PLACEHOLDER_EMAIL || password === PLACEHOLDER_PASSWORD) {
    throw new Error('Replace the placeholder values in backend/admin-credentials.env before running create-admin.');
  }

  const prisma = new PrismaClient();
  try {
    const passwordHash = await hashPassword(password);
    const user = await prisma.user.upsert({
      where: { email },
      update: { role: 'admin', passwordHash },
      create: { email, role: 'admin', passwordHash, name: 'Zubix Admin', isProfileComplete: true },
    });
    console.log(`Admin account ready: ${user.email} (role=${user.role})`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
