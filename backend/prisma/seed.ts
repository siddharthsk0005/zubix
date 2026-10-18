import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Supabase PostgreSQL database...');

  // 1. Clear existing data
  await prisma.voucherClaim.deleteMany();
  await prisma.session.deleteMany();
  await prisma.brand.deleteMany();
  await prisma.category.deleteMany();

  // 2. Insert Categories
  const catFashion = await prisma.category.create({
    data: {
      id: 'cat_fashion',
      name: 'Fashion and Lifestyle',
      slug: 'fashion-lifestyle',
      iconName: 'checkroom',
      displayOrder: 1,
      isActive: true,
    },
  });

  const catBeauty = await prisma.category.create({
    data: {
      id: 'cat_beauty',
      name: 'Beauty and Body Care',
      slug: 'beauty-body-care',
      iconName: 'spa',
      displayOrder: 2,
      isActive: true,
    },
  });

  const catHome = await prisma.category.create({
    data: {
      id: 'cat_home',
      name: 'Home Essentials',
      slug: 'home-essentials',
      iconName: 'home',
      displayOrder: 3,
      isActive: true,
    },
  });

  const catCosmetics = await prisma.category.create({
    data: {
      id: 'cat_cosmetics',
      name: 'Cosmetics',
      slug: 'cosmetics',
      iconName: 'brush',
      displayOrder: 4,
      isActive: true,
    },
  });

  const catElectronics = await prisma.category.create({
    data: {
      id: 'cat_electronics',
      name: 'Electronics and Devices',
      slug: 'electronics-devices',
      iconName: 'devices',
      displayOrder: 5,
      isActive: true,
    },
  });

  console.log('Categories seeded.');

  // 3. Insert Partner Brands
  const brandAurora = await prisma.brand.create({
    data: {
      id: 'brand_aurora',
      name: 'AURORA Minimal',
      tagline: 'Timeless Monochromatic Streetwear & Silhouettes',
      bio: 'Aurora blends high-density Japanese cotton with architectural silhouettes. Designed for effortless modern wardrobes.',
      logoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://auroraminimal.example.com',
      socialLinks: {
        Instagram: 'https://instagram.com/aurora.minimal',
        X: 'https://x.com/auroraminimal',
        LinkedIn: 'https://linkedin.com/company/aurora-apparel',
      },
      contactEmail: 'partner@auroraminimal.com',
      contactPhone: '+1 (555) 392-8810',
      categoryId: catFashion.id,
      sessionCreatedBy: 'Aman Verma (Lead Curator)',
      isApproved: true,
    },
  });

  const brandBotanica = await prisma.brand.create({
    data: {
      id: 'brand_botanica',
      name: 'Botanica Botanics',
      tagline: 'Cold-Pressed Botanical Body & Skin Elixirs',
      bio: 'Zero-chemical, wild-harvested botanicals crafted for skin barrier restoration and natural glow.',
      logoUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1608248597359-566085a85590?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://botanicabotanics.example.com',
      socialLinks: {
        Instagram: 'https://instagram.com/botanica.official',
        LinkedIn: 'https://linkedin.com/company/botanica-skincare',
      },
      contactEmail: 'press@botanica.com',
      contactPhone: '+1 (555) 782-9901',
      categoryId: catBeauty.id,
      sessionCreatedBy: 'Siddharth Kumawat (Admin)',
      isApproved: true,
    },
  });

  const brandKanso = await prisma.brand.create({
    data: {
      id: 'brand_kanso',
      name: 'KANSO Audio & Tech',
      tagline: 'Precision Acoustic Hi-Fi & Wireless Earwear',
      bio: 'Bespoke precision audio with beryllium drivers and CNC anodized aluminum craftsmanship.',
      logoUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://kansoaudio.example.com',
      socialLinks: {
        Instagram: 'https://instagram.com/kansoaudio',
        X: 'https://x.com/kanso_tech',
      },
      contactEmail: 'hello@kansoaudio.com',
      contactPhone: '+1 (555) 674-8890',
      categoryId: catElectronics.id,
      sessionCreatedBy: 'Zubix Editorial Board',
      isApproved: true,
    },
  });

  console.log('Brands seeded.');

  // 4. Insert Generative Sessions
  await prisma.session.create({
    data: {
      id: 'session_aurora_01',
      brandId: brandAurora.id,
      sessionCreatedBy: 'Aman Verma (Admin)',
      waitingDurationSeconds: 15,
      discountValue: '35% FLAT OFF',
      couponCode: 'ZUBIX-AURORA-35',
      status: 'active',
      totalVouchersPool: 250,
      claimedVouchersCount: 84,
    },
  });

  await prisma.session.create({
    data: {
      id: 'session_botanica_01',
      brandId: brandBotanica.id,
      sessionCreatedBy: 'Siddharth Kumawat',
      waitingDurationSeconds: 20,
      discountValue: '25% OFF + Free Elixir',
      couponCode: 'ZUBIX-BOTANICA-25',
      status: 'active',
      totalVouchersPool: 150,
      claimedVouchersCount: 42,
    },
  });

  await prisma.session.create({
    data: {
      id: 'session_kanso_01',
      brandId: brandKanso.id,
      sessionCreatedBy: 'Zubix Editorial Board',
      waitingDurationSeconds: 25,
      discountValue: '$50 INSTANT VOUCHER',
      couponCode: 'ZUBIX-KANSO-50',
      status: 'active',
      totalVouchersPool: 100,
      claimedVouchersCount: 61,
    },
  });

  console.log('Generative Sessions seeded successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
