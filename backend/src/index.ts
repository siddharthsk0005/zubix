import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// In-Memory fallback store if PostgreSQL is still spinning up or initializing
let mockCategories = [
  { id: 'cat_fashion', name: 'Fashion and Lifestyle', slug: 'fashion-lifestyle', iconName: 'checkroom', displayOrder: 1, isActive: true },
  { id: 'cat_beauty', name: 'Beauty and Body Care', slug: 'beauty-body-care', iconName: 'spa', displayOrder: 2, isActive: true },
  { id: 'cat_home', name: 'Home Essentials', slug: 'home-essentials', iconName: 'home', displayOrder: 3, isActive: true },
  { id: 'cat_cosmetics', name: 'Cosmetics', slug: 'cosmetics', iconName: 'brush', displayOrder: 4, isActive: true },
  { id: 'cat_electronics', name: 'Electronics and Devices', slug: 'electronics-devices', iconName: 'devices', displayOrder: 5, isActive: true },
];

let mockBrands = [
  {
    id: 'brand_aurora',
    name: 'AURORA Minimal',
    tagline: 'Timeless Monochromatic Streetwear & Silhouettes',
    bio: 'Aurora blends high-density Japanese cotton with architectural silhouettes.',
    logoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
    showcaseImages: [
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&auto=format&fit=crop&q=80',
    ],
    websiteUrl: 'https://auroraminimal.example.com',
    socialLinks: { Instagram: 'https://instagram.com/aurora.minimal' },
    contactEmail: 'partner@auroraminimal.com',
    contactPhone: '+1 (555) 392-8810',
    categoryId: 'cat_fashion',
    sessionCreatedBy: 'Aman Verma (Lead Curator)',
    isApproved: true,
  },
];

let mockSessions = [
  {
    id: 'session_aurora_01',
    brandId: 'brand_aurora',
    sessionCreatedBy: 'Aman Verma (Admin)',
    waitingDurationSeconds: 15,
    discountValue: '35% FLAT OFF',
    couponCode: 'ZUBIX-AURORA-35',
    status: 'active',
    totalVouchersPool: 250,
    claimedVouchersCount: 84,
  },
];

let mockVouchers = [
  {
    id: 'vouch_seed_01',
    code: 'ZUBIX-AURORA-WELCOME',
    brandName: 'AURORA Minimal',
    brandLogoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
    brandWebsite: 'https://auroraminimal.example.com',
    discountValue: '20% OFF',
    categoryName: 'Fashion and Lifestyle',
    claimedAt: new Date(),
    expiresAt: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
    isRedeemed: false,
    terms: 'Valid on official checkout.',
  },
];

// Health Check
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'zubix-api', timestamp: new Date() });
});

// ----------------------------------------------------
// 1. CATEGORIES API
// ----------------------------------------------------
app.get('/api/categories', (_req: Request, res: Response) => {
  res.json(mockCategories);
});

app.post('/api/categories', (req: Request, res: Response) => {
  const { name, iconName = 'category' } = req.body;
  if (!name) return res.status(400).json({ error: 'Category name is required' });

  const newCategory = {
    id: `cat_${Date.now()}`,
    name,
    slug: name.toLowerCase().replace(/\s+/g, '-'),
    iconName,
    displayOrder: mockCategories.length + 1,
    isActive: true,
  };
  mockCategories.push(newCategory);
  res.status(201).json(newCategory);
});

app.put('/api/categories/:id', (req: Request, res: Response) => {
  const { id } = req.params;
  const { name, isActive } = req.body;

  const cat = mockCategories.find((c) => c.id === id);
  if (!cat) return res.status(404).json({ error: 'Category not found' });

  if (name !== undefined) cat.name = name;
  if (isActive !== undefined) cat.isActive = isActive;

  res.json(cat);
});

// ----------------------------------------------------
// 2. BRANDS API
// ----------------------------------------------------
app.get('/api/brands', (req: Request, res: Response) => {
  const { categoryId, approvedOnly } = req.query;
  let result = mockBrands;

  if (categoryId) {
    result = result.filter((b) => b.categoryId === categoryId);
  }
  if (approvedOnly === 'true') {
    result = result.filter((b) => b.isApproved);
  }

  res.json(result);
});

app.post('/api/brands', (req: Request, res: Response) => {
  const brandData = req.body;
  const newBrand = {
    id: `brand_${Date.now()}`,
    ...brandData,
    isApproved: false, // Brand requires admin approval
  };
  mockBrands.push(newBrand);
  res.status(201).json(newBrand);
});

app.put('/api/brands/:id/approve', (req: Request, res: Response) => {
  const { id } = req.params;
  const { isApproved } = req.body;

  const brand = mockBrands.find((b) => b.id === id);
  if (!brand) return res.status(404).json({ error: 'Brand not found' });

  brand.isApproved = isApproved ?? true;
  res.json(brand);
});

// ----------------------------------------------------
// 3. GENERATIVE SESSIONS API
// ----------------------------------------------------
app.get('/api/sessions/active', (_req: Request, res: Response) => {
  const active = mockSessions.filter((s) => s.status === 'active');
  res.json(active);
});

app.post('/api/sessions', (req: Request, res: Response) => {
  const { brandId, sessionCreatedBy, waitingDurationSeconds, discountValue, couponCode } = req.body;

  const newSession = {
    id: `session_${Date.now()}`,
    brandId,
    sessionCreatedBy: sessionCreatedBy || 'Admin Curators',
    waitingDurationSeconds: waitingDurationSeconds || 30,
    discountValue,
    couponCode: couponCode ? couponCode.toUpperCase() : `ZUBIX-${Date.now().toString().slice(-4)}`,
    status: 'active',
    totalVouchersPool: 100,
    claimedVouchersCount: 0,
  };

  mockSessions.push(newSession);
  res.status(201).json(newSession);
});

app.post('/api/sessions/:id/claim', (req: Request, res: Response) => {
  const { id } = req.params;
  const session = mockSessions.find((s) => s.id === id);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  const brand = mockBrands.find((b) => b.id === session.brandId);
  session.claimedVouchersCount++;

  const newVoucher = {
    id: `vouch_${Date.now()}`,
    code: session.couponCode,
    brandName: brand?.name || 'Partner Brand',
    brandLogoUrl: brand?.logoUrl || '',
    brandWebsite: brand?.websiteUrl || '',
    discountValue: session.discountValue,
    categoryName: 'Featured',
    claimedAt: new Date(),
    expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    isRedeemed: false,
    terms: 'Valid on partner store.',
  };

  mockVouchers.unshift(newVoucher);
  res.status(201).json(newVoucher);
});

// ----------------------------------------------------
// 4. VOUCHERS API
// ----------------------------------------------------
app.get('/api/vouchers', (_req: Request, res: Response) => {
  res.json(mockVouchers);
});

app.put('/api/vouchers/:id/redeem', (req: Request, res: Response) => {
  const { id } = req.params;
  const voucher = mockVouchers.find((v) => v.id === id);
  if (!voucher) return res.status(404).json({ error: 'Voucher not found' });

  voucher.isRedeemed = true;
  res.json(voucher);
});

app.listen(port, () => {
  console.log(`[Zubix Backend] Server running on http://localhost:${port}`);
});
