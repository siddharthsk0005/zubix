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
│ • Discover D2C   │      │ • Gateway Screen │      │ • Brand Review   │
│ • Nearby Stores  │      │ • Brand Login    │      │ • Drop Review    │
│ • Generative Drop│      │ • Registration   │      │ • Catalog Mgmt   │
│ • Voucher Wallet │      │ • Dashboard      │      │ • Analytics      │
└──────────────────┘      └──────────────────┘      └──────────────────┘
```

---

## 3. The 3 Core Interfaces

### 3.1 Shopper Mobile App (`/`)
- **Discover Screen** (`lib/screens/discover_screen.dart`):
  - Featured banner carousel.
  - Generative Session cards with live countdown timers and participant counters.
  - D2C online brand showcases.
- **Nearby Screen** (`lib/screens/nearby_screen.dart`):
  - Proximity-based local physical stores.
  - Interactive map/list toggle.
  - Store details: address, area, city, operating hours, phone dialer action, map directions.
  - In-store instant coupon claiming.
- **Vouchers Screen** (`lib/screens/vouchers_screen.dart`):
  - Digital wallet of claimed vouchers.
  - Tapping a voucher opens the modal (`lib/widgets/barcode_qr_display.dart`) with interactive high-resolution Code-128 barcode and QR code for cashier scanning.
- **Shopper Auth & Onboarding** (`lib/screens/login_signup_screen.dart`, `lib/screens/profile_onboarding_screen.dart`):
  - Phone number verification with OTP.
  - Social authentication (Apple, Google).
  - Profile preferences & demographics.

### 3.2 Brand Partner Portal (`/brands`, `/brands/login`, `/brands/register`)
- **Brand Gateway (`BrandPortalScreen`)**:
  - Unauthenticated users see a minimalist 2-button gateway:
    1. **`[ Login ]`**: Opens email & password sign-in form.
    2. **`[ Register ]`**: Opens multi-step brand onboarding application.
- **Brand Registration (`BrandRegisterScreen`)**:
  - Supports two types of brands:
    - `online_d2c`: Online D2C Brand (Discover section).
    - `local_store`: Nearby Physical Store (Nearby section, requires address, area, city, hours).
  - Collects brand name, category, website, Instagram, owner email, password, and coupon rules.
- **Brand Partner Dashboard** (`lib/screens/brand_portal_screen.dart`):
  - **Overview**: Brand approval status, voucher claim metrics, total engagement.
  - **My Sessions**: Past, active, and upcoming generative sessions.
  - **Request Session**: Propose a new drop session to Admin (date, time, discount %, quota).
  - **Brand Profile**: Update brand assets, hours, and store details.

### 3.3 Admin Management Panel (`/admin`)
- **Admin Dashboard** (`lib/screens/web_dashboard_screen.dart` for Desktop Web, `lib/screens/admin_screen.dart` for Mobile):
  - **Brand Partner Applications**: Approve or Reject brand registration requests with review notes.
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
| `/brands` | `BrandPortalScreen` | Public / Brand Partner | 2-button gateway if unauthenticated; Dashboard if logged in |
| `/brands/login` | `BrandPortalScreen` (mode: login) | Public | Direct link to Brand Login form |
| `/brands/register`| `BrandRegisterScreen` | Public | Multi-step Brand Registration onboarding |
| `/admin` | `WebDashboardScreen` | Admin | Internal platform management console |

---

## 5. State Management & Data Flow

- **Primary Source of Truth**: `AppState` (`lib/state/app_state.dart`).
- **Reactive Pattern**: `ChangeNotifier` with `ListenableBuilder` wrapped around `MaterialApp` in `lib/main.dart`.
- **Persistence**: `SharedPreferences` saves brand registrations, session requests, vouchers, and active sessions locally on web and mobile.
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
   └── Drop goes live in Shopper "Discover" feed!
```

---

## 8. Design System & Theming

- **Tokens & Definitions**: `lib/theme/app_theme.dart`
- **Aesthetic**: Luxury, sleek, high-contrast monochrome (pure black `#000000`, crisp white `#FFFFFF`, zinc gray accents `#F3F4F6`, `#E5E7EB`).
- **Typography**: Apple/Inter styling with negative letter spacing (`-0.5px`) for modern headlines.
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
   - When updating the web build, ensure `/admin/index.html`, `/brands/index.html`, `/brands/login/index.html`, and `/brands/register/index.html` are synced with `build/web/index.html` for single-page app direct refreshes.
5. **ZERO LINT ERRORS**:
   - Ensure `flutter analyze` passes with 0 errors and 0 warnings before concluding any task.
