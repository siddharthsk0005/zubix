# Zubix — Project Architecture & Context Reference

> **For Developers & AI Coding Assistants (GitHub Copilot, Cursor, etc.)**
> This file contains the complete technical overview, data schema, system flows, and design guidelines for the **Zubix** commerce ecosystem.

---

## 📌 Table of Contents
1. [Overview & Concept](#1-overview--concept)
2. [Ecosystem Architecture](#2-ecosystem-architecture)
3. [The 3 Core Interfaces](#3-the-3-core-interfaces)
4. [Routing & Web URLs](#4-routing--web-urls)
5. [State Management & Data Flow](#5-state-management--data-flow)
6. [Data Models Reference](#6-data-models-reference)
7. [Brand Partner Lifecycle](#7-brand-partner-lifecycle)
8. [Design System & Theming](#8-design-system--theming)
9. [Development Best Practices & Rules](#9-development-best-practices--rules)

---

## 1. Overview & Concept
**Zubix** is an omnichannel luxury commerce platform that merges digital generative drop sessions with local physical retail discovery.
- **D2C Brands** host scheduled, high-energy "Generative Drop Sessions" where online shoppers participate in real time to claim exclusive limited-quantity discount vouchers.
- **Nearby Local Physical Stores** give shoppers proximity-based store discovery, interactive directions, contact details, operating hours, and instant in-store discount codes.
- **Shoppers** maintain a digital voucher wallet with high-resolution, scannable QR codes and Code-128 barcodes for in-store redemption.

---

## 2. Ecosystem Architecture

```
                       ┌────────────────────────┐
                       │     Zubix App State    │
                       │ (lib/state/app_state)  │
                       └───────────┬────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│  Shopper App     │      │  Brand Portal    │      │  Admin Console   │
│  Route: /        │      │  Route: /brands  │      │  Route: /admin   │
│                  │      │                  │      │                  │
│ • Brands (D2C)   │      │ • Gateway Screen │      │ • Brand Review   │
│ • Nearby Stores  │      │ • Brand Login    │      │ • Drop Review    │
│ • Vouchers/Profile│     │ • Registration   │      │ • Catalog Mgmt   │
│ • Voucher Wallet │      │ • Dashboard      │      │ • Analytics      │
└──────────────────┘      └──────────────────┘      └──────────────────┘
```

---

## 3. The 3 Core Interfaces

### 3.1 Shopper Mobile App (`/`)
- **Bottom navigation** (`lib/screens/main_shell.dart`), 4 tabs: Brands, Nearby, My Vouchers, Profile. The former Generative tab was removed. Sessions are joined from Brands or Nearby and open the session room (`GenerativeSessionScreen`) as a pushed route. Back navigation is blocked during the countdown.
- **Brands Screen** (`lib/screens/discover_screen.dart`, tab label "Brands"):
  - Featured banner carousel.
  - Generative Session cards with live countdown timers and participant counters.
  - D2C online brand showcases.
- **Nearby Screen** (`lib/screens/nearby_screen.dart`):
  - Proximity-based local physical stores.
  - Interactive map/list toggle.
  - Store details: address, area, city, operating hours, phone dialer action, map directions.
  - In-store instant coupon claiming.
- **Vouchers Screen** (`lib/screens/vouchers_screen.dart`, tab label "My Vouchers"):
  - Digital wallet of claimed vouchers.
  - Tapping a voucher opens the modal (`lib/widgets/barcode_qr_display.dart`) with interactive high-resolution Code-128 barcode and QR code for cashier scanning.
- **Profile Screen** (`lib/screens/profile_screen.dart`, tab label "Profile"):
  - Account summary, voucher wallet count, preference list, and Sign Out.
- **Shopper Auth & Onboarding** (`lib/screens/login_signup_screen.dart`, `lib/screens/profile_onboarding_screen.dart`):
  - Phone number verification with OTP. Non-production sends return `devOtp` so the code shows on screen.
  - Social authentication (Apple, Google).
  - New shoppers (OTP or social) start with `approvalStatus: "draft"` and complete their profile. Submitting the profile sets `approvalStatus: "pending"`, and an admin must approve it. A pending shopper sees `ApprovalStatusScreen`, which polls `GET /api/auth/approval-status/:userId` and continues into the app once approved. Rejected shoppers see a rejection message. Login itself is not blocked, so the app decides the screen from `approvalStatus`.
  - Profile preferences & demographics.

### 3.2 Brand Partner Portal (`/brands`, `/brands/register`)
- **Brand Gateway (`BrandPortalScreen`)**:
  - Unauthenticated users see a minimalist 2-button gateway:
    1. **`[ Login ]`**: Opens email & password sign-in form (`POST /api/brand/login`).
    2. **`[ Register ]`**: Opens multi-step brand onboarding application.
- **Brand Registration (`BrandRegisterScreen`)**:
  - Supports two types of brands:
    - `online_d2c`: Online D2C Brand (Brands tab).
    - `local_store`: Nearby Physical Store (Nearby section, requires address, area, city, hours).
  - Collects brand name, category, website, Instagram, owner email, password, and coupon rules.
- **Brand Partner Dashboard** (`lib/screens/brand_portal_screen.dart`):
  - **Overview**: Brand approval status, voucher claim metrics, total engagement.
  - **My Sessions**: Past, active, and upcoming generative sessions.
  - **Request Session**: Propose a new drop session to Admin (date, time, discount %, quota).
  - **Brand Profile**: Update brand assets, hours, and store details.

### 3.3 Admin Management Panel (`/admin`)
- **Admin Console** (`lib/screens/admin_gate.dart` gates sign-in; `lib/screens/admin_screen.dart` is the console). Admins are created manually with `npm run create-admin` in `backend/`. There is no public signup.
  - **Brand Partner Applications**: Approve or Reject brand registration requests with review notes.
  - **Customer Approvals**: Lists shopper sign-ups submitted for review (name, mobile, email, location, signup date). Approve or reject them. Approved shoppers get into the app on their next status check.
  - **Session Requests**: Approve or Reject proposed brand generative drop sessions.
  - **Active Sessions**: Monitor live drops and participant counts.
  - **Platform Stats**: Total brands, approved partners, claimed vouchers.

---

## 4. Routing & Web URLs

Zubix uses **Path URL Strategy** (`usePathUrlStrategy()`) from `package:flutter_web_plugins/url_strategy.dart` initialized in `lib/main.dart`.
This ensures URLs do **not** have `#` fragments.

| URL Path | Target Screen | Access Level | Description |
|---|---|---|---|
| `/` | `AuthGate` -> `MainShell` | Public / Shopper | Main shopper discovery and coupon app |
| `/brands` | `BrandPortalScreen` | Public / Brand Partner | 2-button gateway (Login / Register); brand dashboard after sign-in |
| `/brands/register`| `BrandPortalScreen` (initial view: register) | Public | Multi-step Brand Registration onboarding |
| `/admin` | `AdminGate` -> `AdminScreen` | Admin | Admin sign-in, then the admin console |

Routes are matched exactly. Matching ignores case and a trailing slash. Any other path, such as `/brands/login` or `/admin/users`, falls back to `/`. The logic lives in `resolveWebRoute` in `lib/main.dart` and is covered by `test/routing_test.dart`.

---

## 5. State Management & Data Flow

- **Primary Source of Truth**: the Express API (`backend/src/index.ts`), accessed through `ApiService` (`lib/services/api_service.dart`) for categories, brands, sessions, vouchers, and auth.
- **Local UI state**: `AppState` (`lib/state/app_state.dart`) is a `ChangeNotifier` wrapped in `ListenableBuilder` around `MaterialApp` in `lib/main.dart`.
- **Riverpod**: `flutter_riverpod` providers (`lib/providers/auth_provider.dart`, `lib/providers/vouchers_provider.dart`) hold auth and voucher state. `sharedPreferencesProvider` is overridden in `main.dart`.
- **Persistence**: `SharedPreferences` stores the logged-in user (`auth_provider.dart`). Brand, session, and voucher data comes from the API.
- **Brand Session**:
  - `AppState.loginBrand(email, password)` verifies credentials against approved brand registrations.
  - Sets `_currentBrandRegistrationId`.
  - Calling `logoutBrand()` resets `_currentBrandRegistrationId = null` and returns user to the 2-button gateway.

---

## 6. Data Models Reference

### `BrandRegistrationModel` (`lib/models/brand_registration_model.dart`)
```dart
class BrandRegistrationModel {
  final String id;
  final String brandName;
  final String brandType; // 'online_d2c' | 'local_store'
  final String categoryId;
  final String ownerName;
  final String ownerEmail;
  final String? phone;
  final String? website;
  final String? instagram;
  final String? description;
  final String? password;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewNote;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  // Local store physical attributes
  final String? city;
  final String? area;
  final String? address;
  final String? operatingHours;
}
```

### `SessionRequestModel` (`lib/models/session_request_model.dart`)
```dart
class SessionRequestModel {
  final String id;
  final String brandId;
  final String brandName;
  final String title;
  final String description;
  final int discountPercent;
  final int maxParticipants;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? adminNote;
  final DateTime createdAt;
}
```

### `NearbyStoreModel` & `BrandModel`
- Located in `lib/models/brand_model.dart`.
- Represents active, approved brands and physical locations displayed in shopper feeds.

### `VoucherModel` (`lib/models/voucher_model.dart`)
- Represents claimed discount coupons with unique voucher codes, expiry timestamps, and barcode string data.

---

## 7. Brand Partner Lifecycle

```
1. Brand Registration
   └── Form at /brands/register
   └── Selects: Online D2C or Local Store
   └── Sets: Owner Email & Password

2. Admin Review
   └── Admin visits /admin
   └── Reviews brand details & social presence
   └── Clicks [Approve] or [Reject]

3. Brand Access
   └── Brand visits /brands
   └── Sees 2-Button Gateway: [Login] or [Register]
   └── Clicks [Login], enters approved Email & Password
   └── Enters Brand Partner Dashboard

4. Launching Generative Drops
   └── Brand submits "Request Session" in dashboard
   └── Admin approves drop request
   └── Drop goes live in Shopper "Brands" feed!
```

### 7.1 Profile Editing

- **Customer** (`PUT /api/auth/profile`, customer token): name, email, country, state, district. Mobile number is locked. Editable from Profile → Edit profile (`lib/widgets/customer_profile_edit_dialog.dart`). Customers who signed in before the token was added must sign in once more.
- **Brand** (`PUT /api/brands/:id/profile`, brand owner or admin): updates the portal registration and the live brand listing together. Editable from the brand portal's Profile section and from the admin Brands tab (`lib/widgets/brand_profile_edit_dialog.dart`). The contact email is also the brand login email. Tagline is not editable here because it exists only on the live brand.
- **Admin** (`GET /api/customers`, `PUT /api/customers/:id`, admin token): the "All customers" list on the Customers tab (`lib/widgets/admin_customers_panel.dart`).

### Brand Media Gallery
- Brands upload ordered images/videos from the brand portal Profile tab (`lib/widgets/brand_media_manager.dart`). Customers see them in the same order on the Brands page (`lib/widgets/brand_media_gallery.dart`, used by `brand_card.dart` when `brand.media` is non-empty; otherwise the legacy `showcaseImages` gallery).
- Storage: Supabase Storage bucket `brand-media` (public). Limits: images (jpg/png/webp) 5 MB, videos (mp4/mov/webm) 20 MB.
- Table `BrandMedia` (`position` orders items). API: `GET/POST /api/brands/:id/media`, `PUT /api/brands/:id/media/order`, `DELETE /api/brands/:id/media/:mediaId`. Requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in `backend/.env`.

### Brand Logo and Social Channels
- Logo: uploaded from the brand portal Profile tab (`lib/widgets/brand_logo_manager.dart`), stored as `Brand.logoUrl` under `logos/<brandId>/` in the `brand-media` bucket (2 MB limit). API: `POST/DELETE /api/brands/:id/logo`.
- Social channels: `socialLinks` JSON on `BrandRegistration` and `Brand`. Keys are `instagram`, `youtube`, `linkedin`, `facebook`, `call`, `whatsapp`. Call and WhatsApp hold phone numbers. The shared list and link builder are in `lib/models/social_channel.dart`. Customer cards (`brand_card.dart`) show only channels with a value, and each opens its link.

---

## 8. Design System & Theming

- **Tokens & Definitions**: `lib/theme/app_theme.dart`
- **Aesthetic**: Luxury, sleek, high-contrast monochrome (pure black `#000000`, crisp white `#FFFFFF`, zinc gray accents `#F3F4F6`, `#E5E7EB`).
- **Typography**: Apple/Inter styling with negative letter spacing (`-0.5px`) for modern headlines. Flutter uses the platform default font. Inter is not bundled yet.
- **Elevations & Borders**: 1px subtle borders (`#E5E7EB`) with soft drop shadows (`blurRadius: 20`, `color: black.withValues(alpha: 0.04)`).
- **Responsive Layout**:
  - `isWide = MediaQuery.of(context).size.width > 860;`
  - When `isWide`: multi-column layouts with persistent navigation sidebars.
  - When mobile (`<860px`): bottom navigation bars and full-width card layouts.

---

## 9. Development Best Practices & Rules

1. **NO FAKE/MOCKUP DATA**:
   - The entire ecosystem has been purged of demo lists and hardcoded IDs (`reg_demo_*`, `sreq_demo_*`).
   - Do NOT re-add mock lists. Test using real user submissions and live approvals.
2. **CLEAN USER-FIRST UX**:
   - Keep unauthenticated screens simple and straightforward.
   - When asked for a simple interface, avoid bulky or overwhelming shells.
3. **URL PATH PRESERVATION**:
   - Always preserve `usePathUrlStrategy()` so direct links (`/brands`, `/admin`) function without `#`.
4. **STATIC ASSET ROUTING ON WEB**:
   - `web/` has a single `index.html`. The web host must rewrite unknown paths (`/admin`, `/brands`, `/brands/register`) to `index.html` so direct refreshes work.
5. **ZERO LINT ERRORS**:
   - Ensure `flutter analyze` passes with 0 errors and 0 warnings before concluding any task.
