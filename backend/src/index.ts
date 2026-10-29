import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient, BrandRegistration } from '@prisma/client';
import { randomInt, randomUUID } from 'crypto';
import { hashPassword, verifyPassword } from './password';
import { issueAdminToken, issueBrandToken, issueUserToken, requireAdmin, requireBrand, requireBrandOrAdmin, requireCustomer } from './admin-auth';

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json({ limit: '30mb' })); // brand media is sent as base64 (20 MB video ≈ 27 MB body)

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
// 0. AUTH & USER PROFILES API (Live Supabase)
// ----------------------------------------------------

// Pending OTPs keyed by phone. Held in memory, so they reset on restart and are not shared across instances.
const OTP_TTL_MS = 5 * 60 * 1000;
const pendingOtps = new Map<string, { code: string; expiresAt: number }>();

// Send OTP
app.post('/api/auth/send-otp', async (req: Request, res: Response) => {
  try {
    const { phone } = req.body;
    if (!phone || String(phone).trim().length < 7) {
      return res.status(400).json({ error: 'Valid mobile number is required' });
    }
    const cleanPhone = String(phone).trim();
    const code = String(randomInt(1000, 10000));
    pendingOtps.set(cleanPhone, { code, expiresAt: Date.now() + OTP_TTL_MS });
    // TODO: dispatch via an SMS gateway (Twilio, MSG91, Firebase). Until then, dev builds log the code.
    const isDev = process.env.NODE_ENV !== 'production';
    if (isDev) {
      console.log(`[dev] OTP for ${cleanPhone}: ${code}`);
    }
    return res.json({
      success: true,
      message: 'OTP dispatched successfully.',
      phone: cleanPhone,
      // Dev builds only: lets the app display the code until an SMS gateway is wired up.
      ...(isDev ? { devOtp: code } : {}),
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

// Check an OTP without creating a user (used by brand registration). Consumes the code on success.
app.post('/api/auth/check-otp', (req: Request, res: Response) => {
  const { phone, otp } = req.body;
  const cleanPhone = String(phone ?? '').trim();
  const pending = pendingOtps.get(cleanPhone);
  if (!pending || pending.expiresAt < Date.now() || pending.code !== String(otp ?? '').trim()) {
    return res.status(400).json({ error: 'Invalid or expired verification code. Please request a new one.' });
  }
  pendingOtps.delete(cleanPhone);
  return res.json({ success: true });
});

// Verify OTP & Login / Pre-Register
app.post('/api/auth/verify-otp', async (req: Request, res: Response) => {
  try {
    const { phone, otp } = req.body;
    if (!phone) return res.status(400).json({ error: 'Mobile number is required' });
    if (!otp) return res.status(400).json({ error: 'OTP code is required' });

    const cleanPhone = String(phone).trim();
    const pending = pendingOtps.get(cleanPhone);
    if (!pending || pending.expiresAt < Date.now() || pending.code !== String(otp).trim()) {
      return res.status(400).json({ error: 'Invalid or expired verification code. Please request a new one.' });
    }
    pendingOtps.delete(cleanPhone);

    let user = await prisma.user.findFirst({
      where: { phone: cleanPhone },
    });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          phone: cleanPhone,
          role: 'consumer',
          isProfileComplete: false,
          approvalStatus: 'draft',
        },
      });
    }

    return res.json({
      success: true,
      isNewUser,
      isProfileComplete: user.isProfileComplete,
      token: issueUserToken(user.id),
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        displayName: user.name || 'Zubix Member',
        name: user.name,
        country: user.country,
        state: user.state,
        district: user.district,
        role: user.role,
        isProfileComplete: user.isProfileComplete,
        approvalStatus: user.approvalStatus,
        createdAt: user.createdAt,
      },
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/social-login', async (req: Request, res: Response) => {
  try {
    const { provider, email, name } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Email is required for social login' });
    }
    const cleanEmail = String(email).toLowerCase().trim();

    let user = await prisma.user.findFirst({
      where: { email: cleanEmail },
    });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          email: cleanEmail,
          name: name ? String(name).trim() : 'Zubix Member',
          role: 'consumer',
          isProfileComplete: false,
          approvalStatus: 'draft',
        },
      });
    }

    return res.json({
      success: true,
      provider: provider || 'social',
      isNewUser,
      isProfileComplete: user.isProfileComplete,
      token: issueUserToken(user.id),
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        displayName: user.name || 'Zubix Member',
        name: user.name,
        country: user.country,
        state: user.state,
        district: user.district,
        role: user.role,
        isProfileComplete: user.isProfileComplete,
        approvalStatus: user.approvalStatus,
        createdAt: user.createdAt,
      },
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

// Complete Profile (Full Name, Mobile Number, Country, State, District)
app.post('/api/auth/complete-profile', async (req: Request, res: Response) => {
  try {
    const { userId, name, phone, country, state, district } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId is required' });
    if (!name || !String(name).trim()) return res.status(400).json({ error: 'Full Name is required' });
    if (!phone || !String(phone).trim()) return res.status(400).json({ error: 'Mobile Number is required' });
    if (!country || !String(country).trim()) return res.status(400).json({ error: 'Country is required' });
    if (!state || !String(state).trim()) return res.status(400).json({ error: 'State is required' });
    if (!district || !String(district).trim()) return res.status(400).json({ error: 'District is required' });

    const existingUser = await prisma.user.findUnique({
      where: { id: String(userId) },
    });

    if (!existingUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Submitting the profile sends the sign-up to admin review. Already-approved users keep their access.
    const updatedUser = await prisma.user.update({
      where: { id: String(userId) },
      data: {
        name: String(name).trim(),
        phone: String(phone).trim(),
        country: String(country).trim(),
        state: String(state).trim(),
        district: String(district).trim(),
        isProfileComplete: true,
        approvalStatus: existingUser.approvalStatus === 'approved' ? 'approved' : 'pending',
      },
    });

    return res.json({
      success: true,
      user: {
        id: updatedUser.id,
        approvalStatus: updatedUser.approvalStatus,
        phone: updatedUser.phone,
        email: updatedUser.email,
        displayName: updatedUser.name || 'Zubix Member',
        name: updatedUser.name,
        country: updatedUser.country,
        state: updatedUser.state,
        district: updatedUser.district,
        role: updatedUser.role,
        isProfileComplete: updatedUser.isProfileComplete,
        createdAt: updatedUser.createdAt,
      },
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function parseCustomerProfile(body: any): { error?: string; data?: { name: string; email: string | null; country: string; state: string; district: string } } {
  const name = String(body?.name ?? '').trim();
  const email = String(body?.email ?? '').trim().toLowerCase();
  const country = String(body?.country ?? '').trim();
  const state = String(body?.state ?? '').trim();
  const district = String(body?.district ?? '').trim();
  if (!name) return { error: 'Full Name is required' };
  if (!country) return { error: 'Country is required' };
  if (!state) return { error: 'State is required' };
  if (!district) return { error: 'District is required' };
  if (email && !EMAIL_PATTERN.test(email)) return { error: 'Enter a valid email address' };
  return { data: { name, email: email || null, country, state, district } };
}

function publicCustomer(user: { id: string; phone: string | null; email: string | null; name: string | null; country: string | null; state: string | null; district: string | null; role: string; isProfileComplete: boolean; approvalStatus: string; createdAt: Date }) {
  return {
    id: user.id,
    phone: user.phone,
    email: user.email,
    displayName: user.name || 'Zubix Member',
    name: user.name,
    country: user.country,
    state: user.state,
    district: user.district,
    role: user.role,
    isProfileComplete: user.isProfileComplete,
    approvalStatus: user.approvalStatus,
    createdAt: user.createdAt,
  };
}

// Customer: edits own profile. Phone is the login ID and stays locked. No re-approval is needed.
app.put('/api/auth/profile', requireCustomer, async (req: Request, res: Response) => {
  try {
    const parsed = parseCustomerProfile(req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const id = String(res.locals.userId);
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user || user.role !== 'consumer') return res.status(404).json({ error: 'User not found' });

    const updated = await prisma.user.update({ where: { id }, data: parsed.data! });
    return res.json({ success: true, user: publicCustomer(updated) });
  } catch (error: any) {
    if (error.code === 'P2002') return res.status(409).json({ error: 'This email is already used by another account' });
    return res.status(500).json({ error: error.message });
  }
});

// Admin: lists every customer (any approval status) for editing.
app.get('/api/customers', requireAdmin, async (_req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      where: { role: 'consumer' },
      orderBy: { createdAt: 'desc' },
      select: { id: true, name: true, phone: true, email: true, country: true, state: true, district: true, approvalStatus: true, createdAt: true },
    });
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: edits any customer's profile.
app.put('/api/customers/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const parsed = parseCustomerProfile(req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user || user.role !== 'consumer') return res.status(404).json({ error: 'Customer not found' });

    const updated = await prisma.user.update({
      where: { id },
      data: parsed.data!,
      select: { id: true, name: true, phone: true, email: true, country: true, state: true, district: true, approvalStatus: true, createdAt: true },
    });
    res.json(updated);
  } catch (error: any) {
    if (error.code === 'P2002') return res.status(409).json({ error: 'This email is already used by another account' });
    res.status(500).json({ error: error.message });
  }
});

// Get User Profile by ID
app.get('/api/auth/me', async (req: Request, res: Response) => {
  try {
    const userId = req.query.userId as string;
    if (!userId) return res.status(400).json({ error: 'userId parameter required' });

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    return res.json({
      id: user.id,
      phone: user.phone,
      email: user.email,
      displayName: user.name || 'Zubix Member',
      name: user.name,
      country: user.country,
      state: user.state,
      district: user.district,
      role: user.role,
      isProfileComplete: user.isProfileComplete,
      approvalStatus: user.approvalStatus,
      createdAt: user.createdAt,
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

// Approval status for a customer's sign-up (polled while waiting for admin review)
app.get('/api/auth/approval-status/:userId', async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: String(req.params.userId) },
      select: { id: true, approvalStatus: true, isProfileComplete: true },
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.json(user);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/register', async (req: Request, res: Response) => {
  try {
    const { email, name, role = 'consumer' } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    let user = await prisma.user.findUnique({
      where: { email: String(email).toLowerCase().trim() },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email: String(email).toLowerCase().trim(),
          name: name ? String(name).trim() : 'Zubix Member',
          role: String(role),
          isProfileComplete: true,
        },
      });
    }

    res.status(201).json({
      id: user.id,
      email: user.email,
      phone: user.phone,
      displayName: user.name || 'Zubix Member',
      role: user.role,
      isProfileComplete: user.isProfileComplete,
      createdAt: user.createdAt,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { email, name } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    let user = await prisma.user.findUnique({
      where: { email: String(email).toLowerCase().trim() },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email: String(email).toLowerCase().trim(),
          name: name ? String(name).trim() : String(email).split('@')[0],
          role: 'consumer',
          isProfileComplete: true,
        },
      });
    }

    res.json({
      id: user.id,
      email: user.email,
      phone: user.phone,
      displayName: user.name || 'Zubix Member',
      role: user.role,
      isProfileComplete: user.isProfileComplete,
      createdAt: user.createdAt,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin accounts are created manually with `npm run create-admin`.
app.post('/api/admin/login', async (req: Request, res: Response) => {
  try {
    const email = String(req.body?.email || '').toLowerCase().trim();
    const password = String(req.body?.password || '');
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || user.role !== 'admin' || !(await verifyPassword(password, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid admin credentials' });
    }

    res.json({
      id: user.id,
      email: user.email,
      displayName: user.name || 'Zubix Admin',
      role: user.role,
      token: issueAdminToken(user.id),
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Brand sign-in uses the email and password from the brand's application.
// Only approved brands get a token.
app.post('/api/brand/login', async (req: Request, res: Response) => {
  try {
    const email = String(req.body?.email || '').toLowerCase().trim();
    const password = String(req.body?.password || '');
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });

    const reg = await prisma.brandRegistration.findFirst({
      where: { ownerEmail: email },
      orderBy: { appliedAt: 'desc' },
    });
    if (!reg || !(await verifyPassword(password, reg.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (reg.status === 'pending') {
      return res.status(403).json({ error: 'Your brand application is still under review' });
    }
    if (reg.status !== 'approved') {
      return res.status(403).json({ error: 'Your brand application was not approved' });
    }

    const brand = await prisma.brand.findUnique({ where: { id: reg.id } });
    if (!brand) return res.status(403).json({ error: 'Your brand profile is not active yet, please contact Zubix' });

    res.json({
      token: issueBrandToken(brand.id),
      brand,
      registration: toPublicRegistration(reg),
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 1. CATEGORIES API (Live Supabase)
// ----------------------------------------------------
const CATEGORY_SCOPES = ['brand', 'nearby'];

app.get('/api/categories', async (req: Request, res: Response) => {
  try {
    const scope = req.query.scope ? String(req.query.scope) : undefined;
    const categories = await prisma.category.findMany({
      where: scope ? { scope } : undefined,
      orderBy: { displayOrder: 'asc' },
    });
    res.json(categories);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/categories', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { name, iconName = 'category', scope = 'brand' } = req.body;
    if (!name) return res.status(400).json({ error: 'Category name is required' });
    if (!CATEGORY_SCOPES.includes(scope)) {
      return res.status(400).json({ error: "scope must be 'brand' or 'nearby'" });
    }

    const total = await prisma.category.count();
    const slug = name.toLowerCase().replace(/\s+/g, '-');

    const newCategory = await prisma.category.create({
      data: {
        name,
        slug,
        iconName,
        scope,
        displayOrder: total + 1,
        isActive: true,
      },
    });
    res.status(201).json(newCategory);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/categories/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { name, isActive, scope } = req.body;
    if (scope !== undefined && !CATEGORY_SCOPES.includes(scope)) {
      return res.status(400).json({ error: "scope must be 'brand' or 'nearby'" });
    }

    const updated = await prisma.category.update({
      where: { id },
      data: {
        ...(name !== undefined && { name }),
        ...(isActive !== undefined && { isActive }),
        ...(scope !== undefined && { scope }),
      },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/categories/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    await prisma.category.delete({ where: { id } });
    res.json({ success: true, message: 'Category deleted' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Distance calculation helper (Haversine Formula)
function getDistanceFromLatLonInKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

// ----------------------------------------------------
// 2. BRANDS API (Live Supabase)
// ----------------------------------------------------

// Nearby Physical Stores & Boutiques
app.get('/api/brands/nearby', async (req: Request, res: Response) => {
  try {
    const { lat, lng, radiusKm = 50 } = req.query;

    const userLat = lat ? parseFloat(String(lat)) : null;
    const userLng = lng ? parseFloat(String(lng)) : null;
    const maxRadius = parseFloat(String(radiusKm)) || 50;

    let stores = await prisma.brand.findMany({
      where: {
        storeType: 'local_store',
        isApproved: true,
      },
      include: {
        category: true,
        sessions: {
          where: { status: 'active' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Compute distance and filter
    const enriched = stores.map((store) => {
      let distanceKm: number | null = null;
      if (userLat != null && userLng != null && store.latitude != null && store.longitude != null) {
        distanceKm = getDistanceFromLatLonInKm(userLat, userLng, store.latitude, store.longitude);
      }
      return {
        ...store,
        distanceKm,
      };
    });

    // Sort by distance (closest first)
    enriched.sort((a, b) => (a.distanceKm ?? 999) - (b.distanceKm ?? 999));

    res.json(enriched);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/brands', async (req: Request, res: Response) => {
  try {
    const { categoryId, approvedOnly, storeType } = req.query;
    const brands = await prisma.brand.findMany({
      where: {
        ...(categoryId ? { categoryId: String(categoryId) } : {}),
        ...(approvedOnly === 'true' ? { isApproved: true } : {}),
        ...(storeType ? { storeType: String(storeType) } : {}),
      },
      include: {
        category: true,
        sessions: {
          where: { status: 'active' },
        },
        media: {
          orderBy: { position: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(brands);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/brands', requireAdmin, async (req: Request, res: Response) => {
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

app.put('/api/brands/:id/approve', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
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

// Brand or admin: edits the brand profile. The registration (owner details, shown in the brand portal)
// and the live brand (shown to customers) share one id, so both are updated together.
app.put('/api/brands/:id/profile', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only edit your own brand' });
    }
    const body = req.body || {};
    const text = (value: unknown) => (value === undefined ? undefined : String(value ?? '').trim());
    const optional = (value: unknown) => {
      const clean = text(value);
      return clean === undefined ? undefined : clean || null;
    };

    const brandName = text(body.brandName);
    const brandType = text(body.brandType);
    const contactEmail = text(body.contactEmail)?.toLowerCase();
    const contactPhone = text(body.contactPhone);
    const ownerName = text(body.ownerName);
    const categoryId = text(body.categoryId);

    if (brandName !== undefined && !brandName) return res.status(400).json({ error: 'Brand name is required' });
    if (brandType !== undefined && brandType !== 'online_d2c' && brandType !== 'local_store') {
      return res.status(400).json({ error: "brandType must be 'online_d2c' or 'local_store'" });
    }
    if (contactEmail !== undefined && !EMAIL_PATTERN.test(contactEmail)) {
      return res.status(400).json({ error: 'Enter a valid contact email' });
    }
    if (categoryId !== undefined) {
      const category = await prisma.category.findUnique({ where: { id: categoryId } });
      if (!category) return res.status(400).json({ error: 'Selected category does not exist' });
    }

    const websiteUrl = text(body.websiteUrl);
    const instagramUrl = text(body.instagramUrl);
    const description = text(body.description);
    const city = optional(body.city);
    const area = optional(body.area);
    const address = optional(body.address);
    const operatingHours = optional(body.operatingHours);

    // Replace with the submitted map when provided; otherwise keep the saved channels. Instagram is also accepted on its own.
    let socialLinksValue: Record<string, string> | undefined;
    if (body.socialLinks !== undefined || instagramUrl !== undefined) {
      const current = await prisma.brand.findUnique({ where: { id }, select: { socialLinks: true } });
      socialLinksValue = cleanSocialLinks(body.socialLinks !== undefined ? body.socialLinks : current?.socialLinks);
      if (instagramUrl !== undefined) {
        if (instagramUrl) socialLinksValue.instagram = instagramUrl;
        else delete socialLinksValue.instagram;
      }
    }

    const registrationData = {
      ...(brandName !== undefined && { brandName }),
      ...(ownerName && { ownerName }),
      ...(contactPhone !== undefined && { ownerPhone: contactPhone }),
      ...(contactEmail !== undefined && { ownerEmail: contactEmail }),
      ...(brandType !== undefined && { brandType }),
      ...(websiteUrl !== undefined && { websiteUrl: websiteUrl || null }),
      ...(instagramUrl !== undefined && { instagramUrl: instagramUrl || null }),
      ...(socialLinksValue !== undefined && { socialLinks: socialLinksValue }),
      ...(description !== undefined && { description: description || null }),
      ...(categoryId !== undefined && { categoryId }),
      ...(city !== undefined && { city }),
      ...(area !== undefined && { area }),
      ...(address !== undefined && { address }),
      ...(operatingHours !== undefined && { operatingHours }),
    };

    const brandData = {
      ...(brandName !== undefined && { name: brandName }),
      ...(contactEmail !== undefined && { contactEmail }),
      ...(contactPhone !== undefined && { contactPhone }),
      ...(brandType !== undefined && { storeType: brandType, isPhysicalStore: brandType === 'local_store' }),
      ...(websiteUrl !== undefined && { websiteUrl }),
      ...(socialLinksValue !== undefined && { socialLinks: socialLinksValue }),
      ...(description !== undefined && { bio: description }),
      ...(categoryId !== undefined && { categoryId }),
      ...(city !== undefined && { city }),
      ...(area !== undefined && { area }),
      ...(address !== undefined && { address }),
      ...(operatingHours !== undefined && { timings: operatingHours || '10:00 AM - 9:30 PM' }),
    };

    const [, , registration, brand] = await prisma.$transaction([
      prisma.brandRegistration.updateMany({ where: { id }, data: registrationData }),
      prisma.brand.updateMany({ where: { id }, data: brandData }),
      prisma.brandRegistration.findUnique({ where: { id } }),
      prisma.brand.findUnique({ where: { id } }),
    ]);
    if (!registration && !brand) return res.status(404).json({ error: 'Brand not found' });

    res.json({ success: true, registration: registration ? toPublicRegistration(registration) : null, brand });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Brand media: ordered images/videos stored in a public Supabase Storage bucket.
const MEDIA_BUCKET = 'brand-media';
const MB = 1024 * 1024;
const MEDIA_TYPES: Record<string, { kind: 'image' | 'video'; maxBytes: number; ext: string }> = {
  'image/jpeg': { kind: 'image', maxBytes: 5 * MB, ext: 'jpg' },
  'image/png': { kind: 'image', maxBytes: 5 * MB, ext: 'png' },
  'image/webp': { kind: 'image', maxBytes: 5 * MB, ext: 'webp' },
  'video/mp4': { kind: 'video', maxBytes: 20 * MB, ext: 'mp4' },
  'video/quicktime': { kind: 'video', maxBytes: 20 * MB, ext: 'mov' },
  'video/webm': { kind: 'video', maxBytes: 20 * MB, ext: 'webm' },
};

function storageConfig() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    throw new Error('Storage is not configured: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in backend/.env');
  }
  return { baseUrl: url.replace(/\/$/, ''), key };
}

async function uploadMediaFile(path: string, bytes: Buffer, mimeType: string): Promise<string> {
  const { baseUrl, key } = storageConfig();
  const res = await fetch(`${baseUrl}/storage/v1/object/${MEDIA_BUCKET}/${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, apikey: key, 'Content-Type': mimeType, 'x-upsert': 'false' },
    body: new Uint8Array(bytes),
  });
  if (!res.ok) throw new Error(`Storage upload failed (${res.status}): ${await res.text()}`);
  return `${baseUrl}/storage/v1/object/public/${MEDIA_BUCKET}/${path}`;
}

async function removeMediaFile(path: string): Promise<void> {
  const { baseUrl, key } = storageConfig();
  const res = await fetch(`${baseUrl}/storage/v1/object/${MEDIA_BUCKET}/${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${key}`, apikey: key },
  });
  if (!res.ok && res.status !== 404) throw new Error(`Storage delete failed (${res.status})`);
}

app.get('/api/brands/:id/media', async (req: Request, res: Response) => {
  try {
    const media = await prisma.brandMedia.findMany({
      where: { brandId: String(req.params.id) },
      orderBy: { position: 'asc' },
    });
    res.json(media);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/brands/:id/media', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only upload media for your own brand' });
    }
    const { mimeType, dataBase64 } = req.body || {};
    const spec = MEDIA_TYPES[String(mimeType)];
    if (!spec) {
      return res.status(400).json({ error: 'Unsupported file type. Use JPG, PNG, WEBP, MP4, MOV or WEBM.' });
    }
    if (typeof dataBase64 !== 'string' || !dataBase64) {
      return res.status(400).json({ error: 'File data is missing' });
    }
    const bytes = Buffer.from(dataBase64, 'base64');
    if (bytes.length === 0) {
      return res.status(400).json({ error: 'File data is empty' });
    }
    if (bytes.length > spec.maxBytes) {
      const limit = spec.kind === 'image' ? '5 MB' : '20 MB';
      return res.status(413).json({ error: `${spec.kind === 'image' ? 'Images' : 'Videos'} must be ${limit} or smaller` });
    }
    const brand = await prisma.brand.findUnique({ where: { id }, select: { id: true } });
    if (!brand) return res.status(404).json({ error: 'Brand not found' });

    const path = `${id}/${randomUUID()}.${spec.ext}`;
    const publicUrl = await uploadMediaFile(path, bytes, String(mimeType));
    try {
      const created = await prisma.$transaction(async (tx) => {
        const last = await tx.brandMedia.aggregate({ where: { brandId: id }, _max: { position: true } });
        return tx.brandMedia.create({
          data: {
            brandId: id,
            kind: spec.kind,
            url: publicUrl,
            storagePath: path,
            mimeType: String(mimeType),
            sizeBytes: bytes.length,
            position: (last._max.position ?? -1) + 1,
          },
        });
      });
      res.status(201).json(created);
    } catch (error) {
      await removeMediaFile(path).catch(() => undefined);
      throw error;
    }
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/brands/:id/media/order', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only reorder your own brand media' });
    }
    const ids = req.body?.ids;
    const existing = await prisma.brandMedia.findMany({ where: { brandId: id }, select: { id: true } });
    const existingIds = new Set(existing.map((item) => item.id));
    const valid =
      Array.isArray(ids) &&
      ids.length === existingIds.size &&
      new Set(ids).size === ids.length &&
      ids.every((item) => typeof item === 'string' && existingIds.has(item));
    if (!valid) {
      return res.status(400).json({ error: 'ids must list every media item of this brand exactly once' });
    }
    await prisma.$transaction(
      ids.map((mediaId: string, index: number) =>
        prisma.brandMedia.update({ where: { id: mediaId }, data: { position: index } }),
      ),
    );
    const media = await prisma.brandMedia.findMany({ where: { brandId: id }, orderBy: { position: 'asc' } });
    res.json(media);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/brands/:id/media/:mediaId', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only delete your own brand media' });
    }
    const item = await prisma.brandMedia.findFirst({ where: { id: String(req.params.mediaId), brandId: id } });
    if (!item) return res.status(404).json({ error: 'Media not found' });

    await prisma.brandMedia.delete({ where: { id: item.id } });
    await removeMediaFile(item.storagePath).catch((error) => console.warn('Could not remove media file:', error.message));

    const remaining = await prisma.brandMedia.findMany({ where: { brandId: id }, orderBy: { position: 'asc' } });
    await prisma.$transaction(
      remaining.map((media, index) => prisma.brandMedia.update({ where: { id: media.id }, data: { position: index } })),
    );
    res.json({ ok: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

const LOGO_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};
const LOGO_MAX_BYTES = 2 * MB;

// Recovers the bucket path from a public URL so the old file can be removed.
function storagePathFromPublicUrl(url: string): string | null {
  const marker = `/storage/v1/object/public/${MEDIA_BUCKET}/`;
  const index = url.indexOf(marker);
  return index === -1 ? null : url.slice(index + marker.length);
}

async function removeStoredLogo(url: string | null | undefined): Promise<void> {
  const path = url ? storagePathFromPublicUrl(url) : null;
  if (path) await removeMediaFile(path).catch(() => undefined);
}

app.post('/api/brands/:id/logo', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only change the logo of your own brand' });
    }
    const { mimeType, dataBase64 } = req.body || {};
    const ext = LOGO_TYPES[String(mimeType)];
    if (!ext) {
      return res.status(400).json({ error: 'Unsupported file type. Use JPG, PNG or WEBP.' });
    }
    if (typeof dataBase64 !== 'string' || !dataBase64) {
      return res.status(400).json({ error: 'File data is missing' });
    }
    const bytes = Buffer.from(dataBase64, 'base64');
    if (bytes.length === 0) {
      return res.status(400).json({ error: 'File data is empty' });
    }
    if (bytes.length > LOGO_MAX_BYTES) {
      return res.status(413).json({ error: 'Logos must be 2 MB or smaller' });
    }
    const brand = await prisma.brand.findUnique({ where: { id }, select: { id: true, logoUrl: true } });
    if (!brand) return res.status(404).json({ error: 'Brand not found' });

    const path = `logos/${id}/${randomUUID()}.${ext}`;
    const logoUrl = await uploadMediaFile(path, bytes, String(mimeType));
    try {
      await prisma.brand.update({ where: { id }, data: { logoUrl } });
    } catch (error) {
      await removeMediaFile(path).catch(() => undefined);
      throw error;
    }
    await removeStoredLogo(brand.logoUrl);
    res.json({ logoUrl });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/brands/:id/logo', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only change the logo of your own brand' });
    }
    const brand = await prisma.brand.findUnique({ where: { id }, select: { logoUrl: true } });
    if (!brand) return res.status(404).json({ error: 'Brand not found' });
    await prisma.brand.update({ where: { id }, data: { logoUrl: '' } });
    await removeStoredLogo(brand.logoUrl);
    res.json({ logoUrl: '' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/brands/:id', requireBrandOrAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    if (!res.locals.isAdmin && res.locals.brandId !== id) {
      return res.status(403).json({ error: 'You can only edit your own brand' });
    }
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
      isPhysicalStore,
      storeType,
      city,
      area,
      address,
      latitude,
      longitude,
      googleMapsUrl,
      timings,
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
        ...(socialLinks !== undefined && { socialLinks: cleanSocialLinks(socialLinks) }),
        ...(contactEmail !== undefined && { contactEmail }),
        ...(contactPhone !== undefined && { contactPhone }),
        ...(categoryId !== undefined && { categoryId }),
        ...(isPhysicalStore !== undefined && { isPhysicalStore }),
        ...(storeType !== undefined && { storeType }),
        ...(city !== undefined && { city }),
        ...(area !== undefined && { area }),
        ...(address !== undefined && { address }),
        ...(latitude !== undefined && { latitude: Number(latitude) }),
        ...(longitude !== undefined && { longitude: Number(longitude) }),
        ...(googleMapsUrl !== undefined && { googleMapsUrl }),
        ...(timings !== undefined && { timings }),
      },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/vouchers/verify-redeem', async (req: Request, res: Response) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, message: 'Voucher code is required' });
    }
    const cleanCode = String(code).trim().toUpperCase();
    const voucher = await prisma.voucherClaim.findFirst({
      where: {
        code: {
          equals: cleanCode,
          mode: 'insensitive',
        },
      },
    });

    if (!voucher) {
      return res.status(404).json({ success: false, message: 'Invalid code. Voucher not found.' });
    }

    if (voucher.isRedeemed) {
      return res.json({
        success: false,
        alreadyRedeemed: true,
        voucher,
        message: 'This voucher was ALREADY REDEEMED earlier.',
      });
    }

    const updated = await prisma.voucherClaim.update({
      where: { id: voucher.id },
      data: { isRedeemed: true },
    });

    res.json({
      success: true,
      alreadyRedeemed: false,
      voucher: updated,
      message: 'Voucher verified & redeemed successfully at counter!',
    });
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

app.post('/api/sessions', requireAdmin, async (req: Request, res: Response) => {
  try {
    const {
      brandId,
      sessionCreatedBy = 'Admin Curators',
      waitingDurationSeconds = 15,
      discountValue,
      couponCode,
      totalVouchersPool = 100,
      couponTiers,
      poolReleaseAt,
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
        couponTiers: Array.isArray(couponTiers) ? normalizeCouponTiers(couponTiers) : undefined,
        poolReleaseAt: poolReleaseAt ? new Date(poolReleaseAt) : null,
      },
      include: { brand: true },
    });
    res.status(201).json(newSession);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 3b. GENERATIVE SESSION POOL API
// ----------------------------------------------------
type CouponTierInput = { label?: string; name?: string; slots?: number; discountPct?: number };

// Tier key is the array index as a string, so it stays stable for the life of a session.
function normalizeCouponTiers(tiers: CouponTierInput[]) {
  return tiers.map((t, i) => ({
    key: String(i),
    label: String(t.label ?? t.name ?? `Tier ${i + 1}`),
    slots: Math.max(0, Number(t.slots) || 0),
    discountPct: Number(t.discountPct) || 0,
  }));
}

type StoredTier = { key: string; label: string; slots: number; discountPct: number };
function readTiers(value: unknown): StoredTier[] {
  return Array.isArray(value) ? (value as StoredTier[]) : [];
}

// Moves waiting participations whose accept time has passed into the pool.
async function settleParticipations(filter: { sessionId?: string; userId?: string }) {
  await prisma.sessionParticipation.updateMany({
    where: { ...filter, status: 'waiting', acceptAt: { lte: new Date() } },
    data: { status: 'pooled' },
  });
}

// Join a session. The accept time is computed on the server from the admin's timer.
app.post('/api/sessions/:id/join', async (req: Request, res: Response) => {
  try {
    const sessionId = String(req.params.id);
    const userId = String(req.body?.userId || '');
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const session = await prisma.session.findUnique({ where: { id: sessionId } });
    if (!session) return res.status(404).json({ error: 'Session not found' });
    if (session.status !== 'active') return res.status(409).json({ error: 'Session is not active' });

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const existing = await prisma.sessionParticipation.findUnique({
      where: { sessionId_userId: { sessionId, userId } },
    });
    if (existing) return res.status(409).json({ error: 'You have already joined this session' });

    const joinedAt = new Date();
    const acceptAt = new Date(joinedAt.getTime() + session.waitingDurationSeconds * 1000);
    const created = await prisma.sessionParticipation.create({
      data: { sessionId, userId, joinedAt, acceptAt, status: 'waiting' },
    });
    res.status(201).json(created);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Every session the customer has joined, including released ones, so they cannot rejoin.
app.get('/api/me/joined-sessions', async (req: Request, res: Response) => {
  try {
    const userId = String(req.query.userId || '');
    if (!userId) return res.status(400).json({ error: 'userId is required' });
    const rows = await prisma.sessionParticipation.findMany({
      where: { userId },
      select: { sessionId: true },
    });
    res.json({ sessionIds: rows.map((r) => r.sessionId) });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Customer's Pool: waiting, pooled and allotted-but-not-yet-released sessions.
// Allotments whose release time has passed are excluded because they now live in Vouchers.
app.get('/api/me/pool', async (req: Request, res: Response) => {
  try {
    const userId = String(req.query.userId || '');
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    await settleParticipations({ userId });
    const now = new Date();

    const rows = await prisma.sessionParticipation.findMany({
      where: { userId },
      include: { session: { include: { brand: true } } },
      orderBy: { joinedAt: 'desc' },
    });

    const claimIds = rows.map((r) => r.claimId).filter((c): c is string => !!c);
    const claims = claimIds.length
      ? await prisma.voucherClaim.findMany({ where: { id: { in: claimIds } }, select: { id: true, releaseAt: true, discountValue: true } })
      : [];
    const claimById = new Map(claims.map((c) => [c.id, c]));

    const items = rows
      .map((row) => {
        const tiers = readTiers(row.session.couponTiers);
        const tier = row.tierKey ? tiers.find((t) => t.key === row.tierKey) : undefined;
        const claim = row.claimId ? claimById.get(row.claimId) : undefined;
        return {
          id: row.id,
          sessionId: row.sessionId,
          sessionTitle: row.session.title,
          sessionCreatedBy: row.session.sessionCreatedBy,
          brandName: row.session.brand?.name || 'Partner Brand',
          brandLogoUrl: row.session.brand?.logoUrl || '',
          status: row.status,
          joinedAt: row.joinedAt,
          acceptAt: row.acceptAt,
          acknowledgedAt: row.acknowledgedAt,
          tierKey: row.tierKey,
          tierLabel: tier?.label ?? null,
          discountValue: claim?.discountValue ?? row.session.discountValue,
          releaseAt: claim?.releaseAt ?? null,
          claimId: row.claimId,
        };
      })
      .filter((item) => !(item.status === 'allotted' && (!item.releaseAt || item.releaseAt <= now)));

    res.json(items);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Customer presses "Okay" on the pool acceptance notice. Only pooled entries can be acknowledged.
app.post('/api/me/pool/:id/ack', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const userId = String(req.body?.userId || '');
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const row = await prisma.sessionParticipation.findUnique({ where: { id } });
    if (!row || row.userId !== userId) return res.status(404).json({ error: 'Pool entry not found' });

    await settleParticipations({ userId });
    const fresh = await prisma.sessionParticipation.findUnique({ where: { id } });
    if (!fresh || fresh.status === 'waiting') {
      return res.status(409).json({ error: 'Not accepted into the Pool yet' });
    }
    if (fresh.acknowledgedAt) return res.json(fresh);

    res.json(await prisma.sessionParticipation.update({ where: { id }, data: { acknowledgedAt: new Date() } }));
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: everyone who joined a session, plus per-tier slot usage.
app.get('/api/sessions/:id/participants', requireAdmin, async (req: Request, res: Response) => {
  try {
    const sessionId = String(req.params.id);
    await settleParticipations({ sessionId });

    const session = await prisma.session.findUnique({ where: { id: sessionId }, include: { brand: true } });
    if (!session) return res.status(404).json({ error: 'Session not found' });

    const rows = await prisma.sessionParticipation.findMany({
      where: { sessionId },
      include: { user: { select: { id: true, name: true, phone: true, email: true } } },
      orderBy: { joinedAt: 'asc' },
    });

    const tiers = readTiers(session.couponTiers).map((t) => ({
      ...t,
      allottedCount: rows.filter((r) => r.tierKey === t.key && r.status === 'allotted').length,
    }));

    res.json({
      session: {
        id: session.id,
        title: session.title,
        brandName: session.brand?.name || '',
        status: session.status,
        waitingDurationSeconds: session.waitingDurationSeconds,
        poolReleaseAt: session.poolReleaseAt,
      },
      tiers,
      participants: rows.map((r) => ({
        id: r.id,
        userId: r.userId,
        name: r.user?.name || null,
        phone: r.user?.phone || null,
        email: r.user?.email || null,
        status: r.status,
        joinedAt: r.joinedAt,
        acceptAt: r.acceptAt,
        tierKey: r.tierKey,
      })),
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: sets the waiting timer, the voucher release time and (before any allotment) the tiers.
app.patch('/api/sessions/:id/pool', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { waitingDurationSeconds, poolReleaseAt, couponTiers } = req.body || {};

    const session = await prisma.session.findUnique({ where: { id } });
    if (!session) return res.status(404).json({ error: 'Session not found' });

    const data: Record<string, unknown> = {};
    if (waitingDurationSeconds !== undefined) {
      const seconds = Number(waitingDurationSeconds);
      if (!Number.isFinite(seconds) || seconds < 0) return res.status(400).json({ error: 'Invalid waiting duration' });
      data.waitingDurationSeconds = seconds;
    }
    if (poolReleaseAt !== undefined) {
      const releaseAt = poolReleaseAt ? new Date(poolReleaseAt) : null;
      if (releaseAt && Number.isNaN(releaseAt.getTime())) return res.status(400).json({ error: 'Invalid release time' });
      data.poolReleaseAt = releaseAt;
    }
    if (Array.isArray(couponTiers)) {
      const allotted = await prisma.sessionParticipation.count({ where: { sessionId: id, status: 'allotted' } });
      if (allotted > 0) return res.status(409).json({ error: 'Tiers cannot change after vouchers are allotted' });
      data.couponTiers = normalizeCouponTiers(couponTiers);
    }

    const updated = await prisma.session.update({ where: { id }, data });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: allots pooled participants to one coupon tier. Each person can be allotted once, and the tier's slot count is a hard limit.
app.post('/api/sessions/:id/allot', requireAdmin, async (req: Request, res: Response) => {
  try {
    const sessionId = String(req.params.id);
    const { tierKey, userIds } = req.body || {};
    const ids: string[] = Array.isArray(userIds) ? [...new Set(userIds.map((u: unknown) => String(u)))] : [];
    if (tierKey === undefined || ids.length === 0) {
      return res.status(400).json({ error: 'tierKey and userIds are required' });
    }

    const session = await prisma.session.findUnique({ where: { id: sessionId }, include: { brand: { include: { category: true } } } });
    if (!session) return res.status(404).json({ error: 'Session not found' });
    if (!session.poolReleaseAt) return res.status(409).json({ error: 'Set the pool release time before allotting vouchers' });

    const tier = readTiers(session.couponTiers).find((t) => t.key === String(tierKey));
    if (!tier) return res.status(400).json({ error: 'Unknown coupon tier' });

    await settleParticipations({ sessionId });

    const eligible = await prisma.sessionParticipation.findMany({
      where: { sessionId, userId: { in: ids }, status: 'pooled' },
    });
    if (eligible.length !== ids.length) {
      const eligibleIds = new Set(eligible.map((e) => e.userId));
      const blocked = ids.filter((u) => !eligibleIds.has(u));
      return res.status(409).json({ error: 'Some users are not in the pool or already allotted', userIds: blocked });
    }

    const result = await prisma.$transaction(async (tx) => {
      const used = await tx.sessionParticipation.count({ where: { sessionId, tierKey: tier.key, status: 'allotted' } });
      if (used + eligible.length > tier.slots) {
        return { error: `Only ${Math.max(0, tier.slots - used)} slot(s) left in "${tier.label}"` };
      }

      const now = new Date();
      for (const participation of eligible) {
        const claim = await tx.voucherClaim.create({
          data: {
            code: session.couponCode,
            brandId: session.brandId,
            sessionId: session.id,
            discountValue: `${tier.discountPct}% OFF`,
            brandWebsite: session.brand?.websiteUrl || '',
            categoryName: session.brand?.category?.name || 'Featured',
            claimedAt: now,
            expiresAt: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
            isRedeemed: false,
            userId: participation.userId,
            terms: 'Official partner store discount. Redeemable at checkout.',
            releaseAt: session.poolReleaseAt,
          },
        });
        await tx.sessionParticipation.update({
          where: { id: participation.id },
          data: { status: 'allotted', tierKey: tier.key, allottedAt: now, claimId: claim.id },
        });
      }
      await tx.session.update({
        where: { id: session.id },
        data: { claimedVouchersCount: { increment: eligible.length } },
      });
      return { allotted: eligible.length };
    });

    if ('error' in result) return res.status(409).json({ error: result.error });
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 4. VOUCHERS API (Live Supabase)
// ----------------------------------------------------
app.get('/api/vouchers', async (req: Request, res: Response) => {
  try {
    const { userId } = req.query;
    const now = new Date();
    const vouchers: any[] = await prisma.voucherClaim.findMany({
      where: {
        ...(userId ? { userId: String(userId) } : {}),
        OR: [{ releaseAt: null }, { releaseAt: { lte: now } }],
      },
      include: { brand: true },
      orderBy: { claimedAt: 'desc' },
    });
    res.json(
      vouchers.map((v) => ({
        ...v,
        brandName: v.brand?.name || 'Partner Brand',
        brandLogoUrl: v.brand?.logoUrl || '',
      }))
    );
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/vouchers/:id/redeem', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const updated = await prisma.voucherClaim.update({
      where: { id },
      data: { isRedeemed: true },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ----------------------------------------------------
// 6. BRAND REGISTRATIONS & SESSION REQUESTS (Live Supabase)
// ----------------------------------------------------
function toPublicRegistration(reg: BrandRegistration) {
  return { ...reg, passwordHash: undefined };
}

// Social/contact channels a brand can link. Call and WhatsApp hold phone numbers; the rest hold URLs.
const SOCIAL_KEYS = ['instagram', 'youtube', 'linkedin', 'facebook', 'call', 'whatsapp'];
function cleanSocialLinks(input: unknown): Record<string, string> {
  const out: Record<string, string> = {};
  if (!input || typeof input !== 'object') return out;
  for (const key of SOCIAL_KEYS) {
    const value = (input as Record<string, unknown>)[key];
    if (typeof value === 'string' && value.trim()) out[key] = value.trim();
  }
  return out;
}

function slugPrefix(name: string): string {
  const clean = name.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
  if (clean.length >= 4) return clean.substring(0, 4);
  return clean || 'BRAND';
}

// Public: a brand submits an application. Password is hashed and never returned.
app.post('/api/brand-registrations', async (req: Request, res: Response) => {
  try {
    const {
      id, brandName, ownerName, ownerPhone = '', ownerEmail, password,
      brandType = 'online_d2c', categoryId, websiteUrl, instagramUrl, socialLinks, description,
      city, area, address, operatingHours,
    } = req.body;

    if (!brandName || !ownerName || !ownerEmail || !password || !categoryId) {
      return res.status(400).json({ error: 'Brand name, owner name, email, password and category are required' });
    }
    if (String(password).length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Reapplying after a rejection replaces the old rejected application.
    if (ownerPhone) {
      await prisma.brandRegistration.deleteMany({ where: { ownerPhone: String(ownerPhone), status: 'rejected' } });
    }

    const created = await prisma.brandRegistration.create({
      data: {
        ...(id && { id: String(id) }),
        brandName,
        ownerName,
        ownerPhone: String(ownerPhone),
        ownerEmail: String(ownerEmail).toLowerCase().trim(),
        passwordHash: await hashPassword(String(password)),
        brandType,
        categoryId,
        websiteUrl: websiteUrl ?? null,
        instagramUrl: instagramUrl ?? null,
        socialLinks: {
          ...cleanSocialLinks(socialLinks),
          ...(instagramUrl && { instagram: String(instagramUrl).trim() }),
        },
        description: description ?? null,
        city: city ?? null,
        area: area ?? null,
        address: address ?? null,
        operatingHours: operatingHours ?? null,
      },
    });
    res.status(201).json(toPublicRegistration(created));
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/brand-registrations', requireAdmin, async (req: Request, res: Response) => {
  try {
    const status = req.query.status ? String(req.query.status) : undefined;
    const regs = await prisma.brandRegistration.findMany({
      where: status ? { status } : undefined,
      orderBy: { appliedAt: 'desc' },
    });
    res.json(regs.map(toPublicRegistration));
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: customer sign-ups awaiting approval (defaults to pending).
app.get('/api/customer-approvals', requireAdmin, async (req: Request, res: Response) => {
  try {
    const status = req.query.status ? String(req.query.status) : 'pending';
    const users = await prisma.user.findMany({
      where: { role: 'consumer', approvalStatus: status },
      orderBy: { createdAt: 'desc' },
      select: { id: true, name: true, phone: true, email: true, country: true, state: true, district: true, approvalStatus: true, createdAt: true },
    });
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: approve or reject a customer sign-up.
app.put('/api/customer-approvals/:id/review', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { action } = req.body;
    if (action !== 'approve' && action !== 'reject') {
      return res.status(400).json({ error: "action must be 'approve' or 'reject'" });
    }
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user || user.role !== 'consumer') return res.status(404).json({ error: 'Customer not found' });

    const updated = await prisma.user.update({
      where: { id },
      data: { approvalStatus: action === 'approve' ? 'approved' : 'rejected' },
      select: { id: true, name: true, phone: true, email: true, country: true, state: true, district: true, approvalStatus: true, createdAt: true },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: approve (creates the live Brand with the same id) or reject.
app.put('/api/brand-registrations/:id/review', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { action, reason, reviewedBy = 'Zubix Admin' } = req.body;
    if (action !== 'approve' && action !== 'reject') {
      return res.status(400).json({ error: "action must be 'approve' or 'reject'" });
    }

    const reg = await prisma.brandRegistration.findUnique({ where: { id } });
    if (!reg) return res.status(404).json({ error: 'Registration not found' });

    const reviewed = { reviewedAt: new Date(), reviewedBy: String(reviewedBy) };

    if (action === 'reject') {
      const updated = await prisma.brandRegistration.update({
        where: { id },
        data: { status: 'rejected', rejectionReason: String(reason || 'Criteria not met'), ...reviewed },
      });
      return res.json(toPublicRegistration(updated));
    }

    const isPhysical = reg.brandType === 'local_store';
    const brandData = {
      name: reg.brandName,
      tagline: isPhysical ? 'Boutique Atelier' : 'Curated D2C Brand',
      bio: reg.description || `${reg.brandName} exclusive collections on Zubix.`,
      logoUrl: '',
      showcaseImages: [],
      websiteUrl: reg.websiteUrl || '',
      socialLinks: {
        ...cleanSocialLinks(reg.socialLinks),
        ...(reg.instagramUrl && { instagram: reg.instagramUrl }),
      },
      contactEmail: reg.ownerEmail,
      contactPhone: reg.ownerPhone,
      categoryId: reg.categoryId,
      isApproved: true,
      isPhysicalStore: isPhysical,
      storeType: reg.brandType,
      city: reg.city,
      area: reg.area,
      address: reg.address,
      timings: reg.operatingHours || '10:00 AM - 9:00 PM',
    };

    const [updated] = await prisma.$transaction([
      prisma.brandRegistration.update({ where: { id }, data: { status: 'approved', ...reviewed } }),
      prisma.brand.upsert({ where: { id }, create: { id, ...brandData }, update: brandData }),
    ]);
    res.json(toPublicRegistration(updated));
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Brand: requests a generative session for its own brand only.
app.post('/api/session-requests', requireBrand, async (req: Request, res: Response) => {
  try {
    const { id, brandId, brandName, brandType = 'online_d2c', requestedDate, couponTiers, additionalNotes, createdBy } = req.body;
    if (!brandId || !brandName || !requestedDate || !Array.isArray(couponTiers) || couponTiers.length === 0) {
      return res.status(400).json({ error: 'Brand, requested date and at least one coupon tier are required' });
    }
    const creatorName = typeof createdBy === 'string' ? createdBy.trim() : '';
    if (!creatorName) {
      return res.status(400).json({ error: 'Session Created By (person name) is required' });
    }
    if (String(brandId) !== res.locals.brandId) {
      return res.status(403).json({ error: 'You can only request sessions for your own brand' });
    }
    const date = new Date(requestedDate);
    if (Number.isNaN(date.getTime())) return res.status(400).json({ error: 'Invalid requested date' });

    const created = await prisma.sessionRequest.create({
      data: {
        ...(id && { id: String(id) }),
        brandId: String(brandId),
        brandName,
        brandType,
        createdBy: creatorName,
        requestedDate: date,
        couponTiers,
        additionalNotes: additionalNotes ?? null,
      },
    });
    res.status(201).json(created);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Brand: lists only its own session requests.
app.get('/api/brand/session-requests', requireBrand, async (_req: Request, res: Response) => {
  try {
    const requests = await prisma.sessionRequest.findMany({
      where: { brandId: res.locals.brandId },
      orderBy: { submittedAt: 'desc' },
    });
    res.json(requests);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/session-requests', requireAdmin, async (req: Request, res: Response) => {
  try {
    const status = req.query.status ? String(req.query.status) : undefined;
    const requests = await prisma.sessionRequest.findMany({
      where: status ? { status } : undefined,
      orderBy: { submittedAt: 'desc' },
    });
    res.json(requests);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: approve (creates the live active session), reject, or propose alternate dates.
app.put('/api/session-requests/:id/review', requireAdmin, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { action, reason, proposedDates, reviewedBy = 'Zubix Admin' } = req.body;
    if (!['approve', 'reject', 'propose'].includes(action)) {
      return res.status(400).json({ error: "action must be 'approve', 'reject' or 'propose'" });
    }

    const existing = await prisma.sessionRequest.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Session request not found' });

    const reviewed = { reviewedAt: new Date(), reviewedBy: String(reviewedBy) };

    if (action === 'reject') {
      const updated = await prisma.sessionRequest.update({
        where: { id },
        data: { status: 'rejected', rejectionReason: String(reason || 'Declined'), ...reviewed },
      });
      return res.json(updated);
    }

    if (action === 'propose') {
      const dates = Array.isArray(proposedDates) ? proposedDates.map((d: string) => new Date(d)) : [];
      if (dates.length === 0 || dates.some((d) => Number.isNaN(d.getTime()))) {
        return res.status(400).json({ error: 'At least one valid proposed date is required' });
      }
      const updated = await prisma.sessionRequest.update({
        where: { id },
        data: { status: 'dates_proposed', proposedDates: dates, ...reviewed },
      });
      return res.json(updated);
    }

    if (existing.status === 'approved') return res.json(existing);

    const brand = await prisma.brand.findUnique({ where: { id: existing.brandId } });
    if (!brand) {
      return res.status(409).json({ error: 'Approve the brand before scheduling its session' });
    }

    const tiers = existing.couponTiers as Array<{ label?: string; name?: string; slots?: number; discountPct?: number }>;
    const topDiscount = tiers[0]?.discountPct ?? 20;
    const totalSlots = tiers.reduce((sum, t) => sum + (Number(t.slots) || 0), 0);

    const [updated] = await prisma.$transaction([
      prisma.sessionRequest.update({ where: { id }, data: { status: 'approved', ...reviewed } }),
      prisma.session.create({
        data: {
          title: `${existing.brandName} Generative Session`,
          brandId: existing.brandId,
          sessionCreatedBy: existing.brandName,
          waitingDurationSeconds: 15,
          discountValue: `${topDiscount}% OFF`,
          couponCode: `ZUBIX-${slugPrefix(existing.brandName)}-${topDiscount}`,
          status: 'active',
          totalVouchersPool: totalSlots,
          couponTiers: normalizeCouponTiers(tiers),
        },
      }),
    ]);
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Brand: confirms one of the dates the admin proposed (own requests only).
app.put('/api/session-requests/:id/confirm', requireBrand, async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const confirmedDate = new Date(req.body?.confirmedDate);
    if (Number.isNaN(confirmedDate.getTime())) return res.status(400).json({ error: 'Invalid confirmed date' });

    const existing = await prisma.sessionRequest.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Session request not found' });
    if (existing.brandId !== res.locals.brandId) {
      return res.status(403).json({ error: 'You can only confirm your own session requests' });
    }
    if (existing.status !== 'dates_proposed') {
      return res.status(409).json({ error: 'No dates are awaiting confirmation for this request' });
    }

    const updated = await prisma.sessionRequest.update({
      where: { id },
      data: { status: 'brand_confirmed', confirmedDate },
    });
    res.json(updated);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

if (!process.env.VERCEL) {
  app.listen(port, () => {
    console.log(`[Zubix Backend] Connected to Supabase & running on http://localhost:${port}`);
  });
}

export default app;
