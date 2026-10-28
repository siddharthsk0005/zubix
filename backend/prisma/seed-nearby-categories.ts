import { PrismaClient } from '@prisma/client';

// Idempotent: creates the default Nearby categories if they don't exist yet.
// Admin can add or rename more later from the admin panel.
const NEARBY_CATEGORIES = ['Cafes', 'Salons', 'Groceries', 'Gym', 'Hotels'];

const prisma = new PrismaClient();

async function main() {
  const total = await prisma.category.count();
  for (const [i, name] of NEARBY_CATEGORIES.entries()) {
    const slug = `nearby-${name.toLowerCase().replace(/\s+/g, '-')}`;
    await prisma.category.upsert({
      where: { slug },
      update: { scope: 'nearby' },
      create: {
        name,
        slug,
        iconName: 'category',
        scope: 'nearby',
        displayOrder: total + i + 1,
        isActive: true,
      },
    });
  }
  const nearby = await prisma.category.findMany({ where: { scope: 'nearby' }, select: { name: true, slug: true } });
  console.log(JSON.stringify(nearby));
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
