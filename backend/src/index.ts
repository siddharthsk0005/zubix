import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', async (_req: Request, res: Response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      status: 'ok',
      service: 'zubix-api',
      database: 'connected (Supabase PostgreSQL)',
      timestamp: new Date(),
    });
  } catch (error: any) {
    res.status(500).json({ status: 'error', database: error.message });
  }
});

// ----------------------------------------------------
// 1. CATEGORIES API (Live Supabase)
// ----------------------------------------------------
app.get('/api/categories', async (_req: Request, res: Response) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { displayOrder: 'asc' },
    });
    res.json(categories);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/categories', async (req: Request, res: Response) => {
  try {
    const { name, iconName = 'category' } = req.body;
    if (!name) return res.status(400).json({ error: 'Category name is required' });

    const total = await prisma.category.count();
    const slug = name.toLowerCase().replace(/\s+/g, '-');

    const newCategory = await prisma.category.create({
      data: {
        name,
        slug,
        iconName,
        displayOrder: total + 1,
        isActive: true,
      },
    });
    res.status(201).json(newCategory);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/categories/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, isActive } = req.body;

    const updated = await prisma.category.update({
      where: { id },
      data: {
        ...(name !== undefined && { name }),
        ...(isActive !== undefined && { isActive }),
      },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/categories/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await prisma.category.delete({ where: { id } });
    res.json({ success: true, message: 'Category deleted' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 2. BRANDS API (Live Supabase)
// ----------------------------------------------------
app.get('/api/brands', async (req: Request, res: Response) => {
  try {
    const { categoryId, approvedOnly } = req.query;
    const brands = await prisma.brand.findMany({
      where: {
        ...(categoryId ? { categoryId: String(categoryId) } : {}),
        ...(approvedOnly === 'true' ? { isApproved: true } : {}),
      },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(brands);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/brands', async (req: Request, res: Response) => {
  try {
    const {
      name,
      tagline,
      bio,
      logoUrl,
      showcaseImages = [],
      websiteUrl,
      socialLinks = {},
      contactEmail,
      contactPhone,
      categoryId,
      sessionCreatedBy = 'Admin Curators',
    } = req.body;

    const brand = await prisma.brand.create({
      data: {
        name,
        tagline: tagline || '',
        bio: bio || '',
        logoUrl: logoUrl || '',
        showcaseImages,
        websiteUrl: websiteUrl || '',
        socialLinks,
        contactEmail: contactEmail || '',
        contactPhone: contactPhone || '',
        categoryId,
        sessionCreatedBy,
        isApproved: false, // Requires admin approval
      },
    });
    res.status(201).json(brand);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/brands/:id/approve', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { isApproved = true } = req.body;

    const updated = await prisma.brand.update({
      where: { id },
      data: { isApproved },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/brands/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      name,
      tagline,
      bio,
      logoUrl,
      showcaseImages,
      websiteUrl,
      socialLinks,
      contactEmail,
      contactPhone,
      categoryId,
    } = req.body;

    const updated = await prisma.brand.update({
      where: { id },
      data: {
        ...(name !== undefined && { name }),
        ...(tagline !== undefined && { tagline }),
        ...(bio !== undefined && { bio }),
        ...(logoUrl !== undefined && { logoUrl }),
        ...(showcaseImages !== undefined && { showcaseImages }),
        ...(websiteUrl !== undefined && { websiteUrl }),
        ...(socialLinks !== undefined && { socialLinks }),
        ...(contactEmail !== undefined && { contactEmail }),
        ...(contactPhone !== undefined && { contactPhone }),
        ...(categoryId !== undefined && { categoryId }),
      },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 3. GENERATIVE SESSIONS API (Live Supabase)
// ----------------------------------------------------
app.get('/api/sessions', async (_req: Request, res: Response) => {
  try {
    const sessions = await prisma.session.findMany({
      include: { brand: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(sessions);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/sessions/active', async (_req: Request, res: Response) => {
  try {
    const active = await prisma.session.findMany({
      where: { status: 'active' },
      include: { brand: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(active);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/sessions', async (req: Request, res: Response) => {
  try {
    const {
      brandId,
      sessionCreatedBy = 'Admin Curators',
      waitingDurationSeconds = 15,
      discountValue,
      couponCode,
      totalVouchersPool = 100,
    } = req.body;

    const newSession = await prisma.session.create({
      data: {
        brandId,
        sessionCreatedBy,
        waitingDurationSeconds: Number(waitingDurationSeconds),
        discountValue,
        couponCode: couponCode ? couponCode.toUpperCase() : `ZUBIX-${Date.now().toString().slice(-4)}`,
        status: 'active',
        totalVouchersPool: Number(totalVouchersPool),
      },
      include: { brand: true },
    });
    res.status(201).json(newSession);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/sessions/:id/claim', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const session = await prisma.session.findUnique({
      where: { id },
      include: { brand: { include: { category: true } } },
    });

    if (!session) return res.status(404).json({ error: 'Session not found' });

    // Increment claimed count
    await prisma.session.update({
      where: { id },
      data: { claimedVouchersCount: { increment: 1 } },
    });

    const claimed = await prisma.voucherClaim.create({
      data: {
        code: session.couponCode,
        brandId: session.brandId,
        sessionId: session.id,
        discountValue: session.discountValue,
        brandWebsite: session.brand.websiteUrl,
        categoryName: session.brand.category?.name || 'Featured',
        claimedAt: new Date(),
        expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        isRedeemed: false,
        terms: 'Official partner store discount. Redeemable at checkout.',
      },
    });

    res.status(201).json({
      ...claimed,
      brandName: session.brand.name,
      brandLogoUrl: session.brand.logoUrl,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 4. VOUCHERS API (Live Supabase)
// ----------------------------------------------------
app.get('/api/vouchers', async (_req: Request, res: Response) => {
  try {
    const vouchers = await prisma.voucherClaim.findMany({
      include: { brand: true },
      orderBy: { claimedAt: 'desc' },
    });
    res.json(
      vouchers.map((v) => ({
        ...v,
        brandName: v.brand.name,
        brandLogoUrl: v.brand.logoUrl,
      }))
    );
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/vouchers/:id/redeem', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const updated = await prisma.voucherClaim.update({
      where: { id },
      data: { isRedeemed: true },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`[Zubix Backend] Connected to Supabase & running on http://localhost:${port}`);
});
