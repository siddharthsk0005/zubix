import { createHmac, randomBytes, timingSafeEqual } from 'crypto';
import { NextFunction, Request, Response } from 'express';

const TOKEN_TTL_MS = 8 * 60 * 60 * 1000;

const secret = process.env.ADMIN_TOKEN_SECRET || randomBytes(32).toString('hex');
if (!process.env.ADMIN_TOKEN_SECRET) {
  console.warn('[Zubix Backend] ADMIN_TOKEN_SECRET is not set; admin sessions reset on every restart.');
}

function sign(payload: string): string {
  return createHmac('sha256', secret).update(payload).digest('base64url');
}

type Role = 'admin' | 'brand' | 'consumer';

interface Claims {
  sub: string;
  role: Role;
  exp: number;
}

function issueToken(role: Role, subject: string): string {
  const payload = Buffer.from(JSON.stringify({ sub: subject, role, exp: Date.now() + TOKEN_TTL_MS })).toString('base64url');
  return `${payload}.${sign(payload)}`;
}

export function issueAdminToken(userId: string): string {
  return issueToken('admin', userId);
}

export function issueBrandToken(brandId: string): string {
  return issueToken('brand', brandId);
}

export function issueUserToken(userId: string): string {
  return issueToken('consumer', userId);
}

function readClaims(req: Request): Claims | null {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const [payload, signature] = token.split('.');
  if (!payload || !signature) return null;

  const expected = Buffer.from(sign(payload));
  const actual = Buffer.from(signature);
  if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) return null;

  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString());
    if (typeof data.sub !== 'string' || typeof data.exp !== 'number' || data.exp < Date.now()) return null;
    if (data.role !== 'admin' && data.role !== 'brand' && data.role !== 'consumer') return null;
    return data as Claims;
  } catch {
    return null;
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const claims = readClaims(req);
  if (!claims || claims.role !== 'admin') {
    return res.status(401).json({ error: 'Admin authentication required' });
  }
  next();
}

// Brand routes: the signed-in brand's id is stored in res.locals.brandId.
export function requireBrand(req: Request, res: Response, next: NextFunction) {
  const claims = readClaims(req);
  if (!claims || claims.role !== 'brand') {
    return res.status(401).json({ error: 'Brand sign-in required, please sign in again' });
  }
  res.locals.brandId = claims.sub;
  next();
}

// Customer routes: the signed-in customer's id is stored in res.locals.userId.
export function requireCustomer(req: Request, res: Response, next: NextFunction) {
  const claims = readClaims(req);
  if (!claims || claims.role !== 'consumer') {
    return res.status(401).json({ error: 'Please sign in again to continue' });
  }
  res.locals.userId = claims.sub;
  next();
}

// Brand-owned writes that admins may also make. Sets res.locals.isAdmin or res.locals.brandId.
export function requireBrandOrAdmin(req: Request, res: Response, next: NextFunction) {
  const claims = readClaims(req);
  if (!claims) return res.status(401).json({ error: 'Sign-in required, please sign in again' });
  if (claims.role === 'admin') {
    res.locals.isAdmin = true;
  } else if (claims.role === 'brand') {
    res.locals.brandId = claims.sub;
  } else {
    return res.status(401).json({ error: 'Brand or admin sign-in required' });
  }
  next();
}
