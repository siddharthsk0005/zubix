# Zubix Copilot Instructions & Architecture Guide

This document is the primary context and guidance file for **GitHub Copilot** and developers working on the **Zubix** ecosystem in VS Code.

---

## 1. Project Overview & Philosophy

**Zubix** is a luxury commerce and interactive discovery ecosystem built using Flutter (supporting Mobile: iOS/Android and Web: Desktop/Tablet).
It connects **D2C Online Brands**, **Nearby Local Physical Stores**, and **High-Intent Shoppers** through timed interactive "Generative Drop Sessions" and instant in-store vouchers.

### The 3 Core Interaction Surfaces:
1. **Shopper Mobile App (`/`)**: Discover online brands, explore nearby local shops, join live interactive drop sessions, claim vouchers, and display scannable QR/barcodes.
2. **Brand Partner Portal (`/brands`, `/brands/login`, `/brands/register`)**: Self-serve gateway for brands. Unauthenticated visitors see a simple two-button gateway (`[ Login ]` & `[ Register ]`). Authenticated brand owners access metrics, session requests, and brand profile management.
3. **Admin Management Panel (`/admin`)**: Internal administrative console for approving/rejecting brand partner applications, reviewing drop session requests, monitoring real-time active sessions, and managing platform catalogs.

---

## 2. Directory Structure & Key Files

```
zubix/
├── .github/
│   └── copilot-instructions.md     <-- This instruction guide for GitHub Copilot
├── backend/                        <-- Node.js + Express + Prisma backend API
│   ├── prisma/schema.prisma
│   └── src/
├── lib/
│   ├── main.dart                   <-- Entry point, Web URL routing, AppState initialization
│   ├── models/
│   │   ├── brand_model.dart        <-- Approved brand representation
│   │   ├── brand_registration_model.dart <-- Onboarding request model (D2C / Local Store)
│   │   ├── category_model.dart     <-- Category definitions
│   │   ├── session_model.dart      <-- Live generative drop session model
│   │   ├── session_request_model.dart <-- Brand session application submitted to Admin
│   │   ├── user_model.dart         <-- Shopper profile model
│   │   └── voucher_model.dart      <-- Claimed voucher tickets (with barcode/QR data)
│   ├── providers/                  <-- Riverpod providers (Auth, Brands, Categories, etc.)
│   ├── screens/
│   │   ├── admin_screen.dart       <-- Mobile-friendly Admin panel
│   │   ├── auth_gate.dart          <-- Shopper authentication router
│   │   ├── brand_partner_dashboard.dart <-- Brand dashboard helper views
│   │   ├── brand_portal_screen.dart <-- /brands portal: Gateway, Login & Dashboard
│   │   ├── brand_register_screen.dart <-- /brands/register: Multi-step registration form
│   │   ├── discover_screen.dart    <-- Shopper Discover tab: D2C brands & drop sessions
│   │   ├── generative_session_screen.dart <-- Live interactive shopping session
│   │   ├── login_signup_screen.dart <-- Shopper phone/OTP & social authentication
│   │   ├── main_shell.dart         <-- Shopper bottom navigation shell (Discover, Nearby, Vouchers)
│   │   ├── nearby_screen.dart      <-- Shopper Nearby tab: Local retail stores & vouchers
│   │   ├── profile_onboarding_screen.dart <-- Shopper demographic preferences onboarding
│   │   ├── vouchers_screen.dart    <-- Shopper claimed voucher wallet
│   │   └── web_dashboard_screen.dart <-- Web-optimized Desktop Admin Panel
│   ├── services/
│   │   ├── api_service.dart        <-- REST client for backend communication
│   │   └── storage/                <-- Local key-value storage helpers
│   ├── state/
│   │   └── app_state.dart          <-- Central reactive state (ChangeNotifier)
│   ├── theme/
│   │   └── app_theme.dart          <-- Luxury monochrome theme tokens (Black/White/Zinc)
│   └── widgets/
│       ├── barcode_qr_display.dart <-- Interactive high-res QR code & Code-128 barcode
│       ├── brand_card.dart         <-- Luxury brand cards for Discover feed
│       ├── profile_modal.dart      <-- Shopper profile & settings bottom sheet
│       ├── swipable_gallery.dart   <-- Media carousel for brand showcases
│       └── voucher_ticket.dart     <-- Luxury voucher ticket with tear-off aesthetics
```

---

## 3. Web URL Routing & Navigation Architecture

In `lib/main.dart`, we configure `usePathUrlStrategy()` from `package:flutter_web_plugins/url_strategy.dart` to completely remove hash routing (`/#/`).

### Route Mappings:
- **`/`**: Default entry point. Opens `AuthGate`, routing authenticated shoppers to `MainShell` (Discover, Nearby, Vouchers) or unauthenticated shoppers to `LoginSignupScreen`.
- **`/brands`**: Brand Partner Portal entry point (`BrandPortalScreen`).
  - **If Unauthenticated**: Renders a clean gateway with **two prominent buttons**: `[ Login ]` and `[ Register ]`. No dashboard sidebar or navigation chrome is displayed.
  - **If Authenticated**: Renders the complete brand partner dashboard (Overview, My Sessions, Request Session, Brand Profile).
- **`/brands/login`**: Direct link to Brand Portal with login mode active.
- **`/brands/register`**: Direct link to Brand Registration form (`BrandRegisterScreen`).
- **`/admin`**: Administrative panel (`WebDashboardScreen` on desktop web, or `AdminScreen` on mobile).

---

## 4. Brand Portal Workflow

### Two Types of Brand Partners:
1. **Online D2C Brands (`online_d2c`)**:
   - Featured in the **Discover** tab.
   - Host interactive Generative Drop Sessions with live participant countdowns and exclusive drop vouchers.
2. **Local Physical Retail Stores (`local_store`)**:
   - Featured in the **Nearby** tab.
   - Display geographic details: Area, City, Full Address, Operating Hours.
   - Offer in-store instant discount coupons with directions and phone dialer actions.

### Registration & Approval Lifecycle:
```
Brand Registration Form (/brands/register)
  │
  ▼ [Status: 'pending']
Admin Review Panel (/admin)
  ├── Reject (Feedback provided, brand can edit and re-apply)
  └── Approve
        │
        ▼ [Status: 'approved']
Brand Login (/brands)
  │  (Email & Password matching approved brand)
  ▼
Brand Dashboard Access
  ├── View Analytics (Claimed vouchers, drop engagement)
  ├── Request Drop Session (Date, time, discount %, quota)
  │     │
  │     ▼ Admin Approves Session
  │     Published to Shoppers in Discover Tab!
  └── Manage Profile & In-Store Coupons
```

---

## 5. State Management & Data Flow

- **Primary State Store**: `AppState` (`lib/state/app_state.dart`) extends `ChangeNotifier`.
  - Holds reactive lists: `brandRegistrations`, `sessionRequests`, `brands`, `nearbyStores`, `sessions`, `myVouchers`.
  - Handles persistence via `SharedPreferences` (`_loadFromStorage()` and `_saveToStorage()`).
  - Handles Brand Login: `loginBrand(email, password)` sets `currentBrandRegistrationId`.
  - Handles Brand Logout: `currentBrandRegistrationId = null`.
- **Riverpod Providers**: Used for user authentication (`auth_provider.dart`), categories, and shopper preferences.

---

## 6. Strict Development Guidelines for GitHub Copilot

When writing or modifying code in this repository, strictly adhere to these rules:

1. **NO MOCK OR DEMO DATA**:
   - Do NOT inject hardcoded dummy lists (e.g. `reg_demo_1`, fake prefilled OTPs like `9001`).
   - All state must support real dynamic submissions, approvals, and lookups.
   - Always provide graceful, high-end empty states (`"No brands registered yet"`, `"No active sessions"`) instead of falling back to fake mockup data.

2. **KEEP UI SIMPLE & INTUITIVE**:
   - When the user asks for a simple interface (e.g. two buttons for Login and Register), do NOT wrap it in complex dashboard shells, sidebars, or nested tabs.
   - Keep unauthenticated screens distraction-free.

3. **LUXURY MONOCHROME DESIGN SYSTEM**:
   - Follow `AppTheme` standards:
     - Pure Black (`#000000`) for primary buttons and high-contrast badges.
     - Pure White (`#FFFFFF`) for elevated cards and backgrounds.
     - Soft grays (`#F8F9FA`, `#F3F4F6`, `#E5E7EB`) for borders and surfaces.
     - High-contrast typography with tight tracking (`letterSpacing: -0.5`).
   - Micro-interactions: subtle animations, smooth transitions, and tactile feedback.

4. **SAFE NULLABILITY & ERROR HANDLING**:
   - Always handle null or missing brand registrations safely (`_brand == null`).
   - When filtering collections, guard against empty lists (`list.isEmpty ? ... : ...`).
   - All text inputs must be trimmed and validated before submission.

5. **PATH ROUTING & RESPONSIVENESS**:
   - Never reintroduce hash-based URLs (`/#/`). Always maintain clean URL path routing via `usePathUrlStrategy()`.
   - Ensure responsive layout checks: `MediaQuery.of(context).size.width > 860` for desktop multi-column layouts vs. mobile single-column layouts.

---

## 7. Useful Commands

```bash
# Analyze code for errors or warnings (must always be 0 issues)
flutter analyze

# Run Flutter web locally with clean port
flutter run -d chrome --web-port=8080

# Build production web bundle
flutter build web --release

# Run Node.js backend
cd backend && npm run dev
```
