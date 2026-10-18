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
// 0. AUTH & USER PROFILES API (Live Supabase)
// ----------------------------------------------------

// Send OTP (Demo OTP: 9001)
app.post('/api/auth/send-otp', async (req: Request, res: Response) => {
  try {
    const { phone } = req.body;
    if (!phone || String(phone).trim().length < 7) {
      return res.status(400).json({ error: 'Valid mobile number is required' });
    }
    const cleanPhone = String(phone).trim();
    // In production, an SMS gateway (Twilio, MSG91, Firebase) would dispatch this.
    // For demo/testing: 9001
    return res.json({
      success: true,
      message: 'OTP dispatched successfully. Use demo code 9001.',
      demoOtp: '9001',
      phone: cleanPhone,
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

// Verify OTP & Login / Pre-Register
app.post('/api/auth/verify-otp', async (req: Request, res: Response) => {
  try {
    const { phone, otp } = req.body;
    if (!phone) return res.status(400).json({ error: 'Mobile number is required' });
    if (!otp) return res.status(400).json({ error: 'OTP code is required' });

    if (String(otp).trim() !== '9001') {
      return res.status(400).json({ error: 'Invalid verification code. Please enter demo OTP 9001.' });
    }

    const cleanPhone = String(phone).trim();

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
        },
      });
    }

    return res.json({
      success: true,
      isNewUser,
      isProfileComplete: user.isProfileComplete,
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
        createdAt: user.createdAt,
      },
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
});

// Social Login (Google / Apple)
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
        },
      });
    }

    return res.json({
      success: true,
      provider: provider || 'social',
      isNewUser,
      isProfileComplete: user.isProfileComplete,
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

    const updatedUser = await prisma.user.update({
      where: { id: String(userId) },
      data: {
        name: String(name).trim(),
        phone: String(phone).trim(),
        country: String(country).trim(),
        state: String(state).trim(),
        district: String(district).trim(),
        isProfileComplete: true,
      },
    });

    return res.json({
      success: true,
      user: {
        id: updatedUser.id,
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
      createdAt: user.createdAt,
    });
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
    const id = String(req.params.id);
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
    const { city, lat, lng, radiusKm = 50 } = req.query;

    // Check if we need to auto-seed local boutiques
    const localStoreCount = await prisma.brand.count({
      where: { isPhysicalStore: true },
    });

    if (localStoreCount === 0) {
      // Find or create default categories
      let cat = await prisma.category.findFirst();
      if (!cat) {
        cat = await prisma.category.create({
          data: { name: 'Fashion and Lifestyle', slug: 'fashion-and-lifestyle', iconName: 'checkroom' },
        });
      }

      await prisma.brand.createMany({
        data: [
          {
            name: 'NOIR Coffee & Concept Atelier',
            tagline: 'Artisan Pour-Overs & Monochrome Lifestyle Objects',
            bio: 'A minimalist sanctuary serving single-origin Ethiopian beans alongside curated brutalist ceramics and Japanese paper goods.',
            logoUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&q=80',
            showcaseImages: [
              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1000&q=80',
              'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1000&q=80',
            ],
            websiteUrl: 'https://noiratelier.example',
            contactEmail: 'concierge@noiratelier.example',
            contactPhone: '+91 80 4123 9901',
            categoryId: cat.id,
            isApproved: true,
            isPhysicalStore: true,
            storeType: 'local_store',
            city: 'Bengaluru',
            area: 'Indiranagar',
            address: '12th Main Rd, HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
            latitude: 12.9716,
            longitude: 77.6412,
            googleMapsUrl: 'https://maps.google.com/?q=Indiranagar+Bengaluru',
            timings: '08:00 AM - 10:30 PM',
            sessionCreatedBy: 'Boutique Curator',
          },
          {
            name: 'THE LINE Menswear & Objects',
            tagline: 'Architectural Silhouettes & Heavyweight Cotton',
            bio: 'Physical flagship boutique showcasing unbranded luxury wardrobe staples, raw denim, and bespoke titanium accessories.',
            logoUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500&q=80',
            showcaseImages: [
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1000&q=80',
              'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=1000&q=80',
            ],
            websiteUrl: 'https://thelinestore.example',
            contactEmail: 'bandra@thelinestore.example',
            contactPhone: '+91 22 2640 8820',
            categoryId: cat.id,
            isApproved: true,
            isPhysicalStore: true,
            storeType: 'local_store',
            city: 'Mumbai',
            area: 'Bandra West',
            address: 'Perry Cross Rd, Off Carter Road, Bandra West, Mumbai, Maharashtra 400050',
            latitude: 19.0596,
            longitude: 72.8295,
            googleMapsUrl: 'https://maps.google.com/?q=Bandra+West+Mumbai',
            timings: '11:00 AM - 09:30 PM',
            sessionCreatedBy: 'Boutique Curator',
          },
          {
            name: 'ATELIER 01 Scent & Leather',
            tagline: 'Hand-Poured Soy Wax & Vegetable-Tanned Goods',
            bio: 'Experiential studio blending custom cold-pressed perfumes with artisanal leather cardholders and travel bags.',
            logoUrl: 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=500&q=80',
            showcaseImages: [
              'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=1000&q=80',
              'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1000&q=80',
            ],
            websiteUrl: 'https://atelier01.example',
            contactEmail: 'hello@atelier01.example',
            contactPhone: '+91 141 400 9001',
            categoryId: cat.id,
            isApproved: true,
            isPhysicalStore: true,
            storeType: 'local_store',
            city: 'Jaipur',
            area: 'C-Scheme',
            address: 'Subhash Marg, C-Scheme, Ashok Nagar, Jaipur, Rajasthan 302001',
            latitude: 26.9124,
            longitude: 75.7873,
            googleMapsUrl: 'https://maps.google.com/?q=C-Scheme+Jaipur',
            timings: '10:30 AM - 08:30 PM',
            sessionCreatedBy: 'Boutique Curator',
          },
          {
            name: 'KURA Avant-Garde Gallery & Retail',
            tagline: 'Modernist Apparel & Japanese Craft',
            bio: 'A heritage courtyard transformed into a high-fashion space featuring limited-run outerwear, titanium eyewear, and gallery prints.',
            logoUrl: 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=500&q=80',
            showcaseImages: [
              'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=1000&q=80',
              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1000&q=80',
            ],
            websiteUrl: 'https://kuragallery.example',
            contactEmail: 'mehrauli@kuragallery.example',
            contactPhone: '+91 11 2664 1200',
            categoryId: cat.id,
            isApproved: true,
            isPhysicalStore: true,
            storeType: 'local_store',
            city: 'Delhi',
            area: 'Mehrauli',
            address: 'One Style Mile, Kalka Das Marg, Mehrauli, New Delhi, Delhi 110030',
            latitude: 28.5245,
            longitude: 77.1855,
            googleMapsUrl: 'https://maps.google.com/?q=Mehrauli+New+Delhi',
            timings: '11:00 AM - 09:00 PM',
            sessionCreatedBy: 'Boutique Curator',
          },
        ],
      });

      // Create live active sessions for these local stores
      const seededStores = await prisma.brand.findMany({ where: { isPhysicalStore: true } });
      for (const store of seededStores) {
        await prisma.session.create({
          data: {
            title: `${store.name} In-Store Generative Drop`,
            brandId: store.id,
            sessionCreatedBy: 'Boutique Store Manager',
            waitingDurationSeconds: 15,
            discountValue: '30% FLAT IN-STORE',
            couponCode: `ZUBIX-LOCAL-${store.name.substring(0, 4).toUpperCase()}`,
            status: 'active',
            totalVouchersPool: 50,
            claimedVouchersCount: 3,
          },
        });
      }
    }

    const cityQuery = city ? String(city).trim() : null;
    const userLat = lat ? parseFloat(String(lat)) : null;
    const userLng = lng ? parseFloat(String(lng)) : null;
    const maxRadius = parseFloat(String(radiusKm)) || 50;

    let stores = await prisma.brand.findMany({
      where: {
        isPhysicalStore: true,
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
      } else if (cityQuery && store.city) {
        const isMatch = store.city.toLowerCase().includes(cityQuery.toLowerCase()) ||
          cityQuery.toLowerCase().includes(store.city.toLowerCase());
        distanceKm = isMatch ? 1.5 : 8.5; // Estimated proximity for city matches
      } else {
        distanceKm = 2.4;
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
      },
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

app.put('/api/brands/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
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
        ...(socialLinks !== undefined && { socialLinks }),
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
    const id = String(req.params.id);
    const { userId } = req.body;
    const session: any = await prisma.session.findUnique({
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
        brandWebsite: session.brand?.websiteUrl || '',
        categoryName: session.brand?.category?.name || 'Featured',
        claimedAt: new Date(),
        expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        isRedeemed: false,
        userId: userId ? String(userId) : null,
        terms: 'Official partner store discount. Redeemable at checkout.',
      },
    });

    res.status(201).json({
      ...claimed,
      brandName: session.brand?.name || 'Partner Brand',
      brandLogoUrl: session.brand?.logoUrl || '',
    });
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
    const vouchers: any[] = await prisma.voucherClaim.findMany({
      where: {
        ...(userId ? { userId: String(userId) } : {}),
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

if (!process.env.VERCEL) {
  app.listen(port, () => {
    console.log(`[Zubix Backend] Connected to Supabase & running on http://localhost:${port}`);
  });
}

export default app;
