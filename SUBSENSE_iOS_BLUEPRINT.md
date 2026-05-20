<div align="center">

# ◈ SUBSENSE iOS ◈
### The Complete Mobile Blueprint

**A Premium Native iOS Application Specification**

`SwiftUI 6` · `iOS 17+` · `Supabase` · `Swift Concurrency` · `WidgetKit` · `Live Activities`

---

*This document is a complete, self-contained product & engineering specification.*
*Feed it to Claude Code (or any agent) to scaffold a production-grade iOS app from zero.*

---

</div>

## 0 · How To Use This Document

> **Audience:** Claude Code (autonomous build agent) or a human iOS engineer.
> **Outcome:** A fully working iOS app that mirrors the SubSense web product, with native iOS polish, a Supabase backend, and a premium freemium model.

**Build order:**
1. Read §1–§4 to understand product & data
2. Provision Supabase using §5 (schema + RLS + functions)
3. Scaffold the Xcode project using §6
4. Implement screens in the order of §8 (Auth → Dashboard → Add Sub → Analytics → Settings → AI)
5. Add native polish from §10 (Widgets, Live Activities, Siri, Push)
6. Ship with checklist in §13

---

## 1 · Product Vision

**SubSense** is a *subscription intelligence* app. It is not a notes app for bills — it is a financial co-pilot that turns the messy, fragmented world of recurring charges (Netflix, Spotify, ChatGPT, iCloud, gym, SaaS tools) into a single, beautiful, actionable picture.

### What makes it different

| | |
|---|---|
| 🧠 | **AI that actually saves money** — detects redundant services, suggests cycle switches, estimates real monthly savings |
| 🌍 | **20+ currencies, real-time** — every subscription kept in its native currency, totals shown in yours |
| 🔔 | **Renewal radar** — local push notifications 3 days before any charge, never get surprise-billed again |
| 📊 | **Honest analytics** — see lifetime spend per service, category breakdowns, "what am I really paying yearly?" |
| 🎨 | **Genuinely beautiful** — glassmorphic, dark-mode-first, brand-color logos for 50+ popular services |
| 🔒 | **Privacy first** — your data lives in your Supabase row; never sold, never aggregated |

### Positioning vs. competitors

- Not a budgeting app like Mint / YNAB (too broad, sub-tracking is an afterthought)
- Not a bank-linked aggregator like Rocket Money (no Plaid, no scary read-access to your bank)
- **Pure focus**: subscriptions, manually-entered, AI-enriched, instantly insightful

---

## 2 · Design Philosophy

### The three pillars

**1. Premium, not playful.**
Inspired by Linear, Things 3, Cron, and Arc. Restrained palette. Tight typography. Hairline borders. Generous whitespace. No emoji-laden empty states. No cartoonish illustrations.

**2. Native, not cross-platform.**
SwiftUI-first. Uses iOS conventions: nav bars with large titles, swipe actions, context menus, sheet detents, `.symbolEffect` animations. Feels like an Apple app, not a wrapped web view.

**3. Instant gratification.**
First-run experience must produce *one piece of value within 30 seconds*. Show monthly spend as soon as the user adds their first subscription. AI insights unlock after 3+ subs added.

### Visual language

- **Glass + grain** — translucent surfaces (`.regularMaterial` on iOS), subtle film grain overlay at 3% opacity on hero surfaces
- **Brand color halos** — each subscription card has a soft radial glow using the service's brand color (Netflix red, Spotify green) at 8–12% alpha
- **Spring animations** — every state change uses `.spring(response: 0.4, dampingFraction: 0.8)`
- **Haptics everywhere** — `.sensoryFeedback(.success, trigger:)` on add, `.impact(.soft)` on tap, `.warning` on delete
- **SF Symbols only** — no custom icon work needed for v1; SF Symbols 5 covers everything

---

## 3 · The Brand

### Name & marks
- **App name (App Store):** SubSense
- **Subtitle:** Track every subscription. Save real money.
- **Bundle ID:** `com.subsense.app`
- **App icon concept:** A single rounded square divided diagonally — top-left a deep indigo gradient (`#6366F1` → `#4338CA`), bottom-right a soft cream (`#FAFAF9`), with a thin glyph of a circular arrow (renewal symbol) overlaid in white. iOS 18+ should ship light/dark/tinted variants.

### Color system

```
Brand
├── Primary       #6366F1  (Indigo 500 — the SubSense purple)
├── Primary Deep  #4338CA  (Indigo 700 — pressed states, gradients)
└── Accent        #F59E0B  (Amber 500 — used sparingly for Pro/AI)

Semantic (light mode)
├── Background    #FAFAF9  (warm off-white — never pure #FFFFFF)
├── Surface       #FFFFFF
├── Surface Alt   #F4F4F5
├── Border        rgba(0,0,0,0.06)
├── Text Primary  #09090B
├── Text Muted    #71717A
├── Success       #10B981
├── Warning       #F59E0B
├── Danger        #EF4444
└── Info          #3B82F6

Semantic (dark mode)
├── Background    #09090B  (near-black, slightly warm)
├── Surface       #18181B
├── Surface Alt   #27272A
├── Border        rgba(255,255,255,0.08)
├── Text Primary  #FAFAFA
├── Text Muted    #A1A1AA
└── (semantic colors same as light)
```

### Typography

iOS native — no custom fonts in v1. Use `SF Pro` system fonts via SwiftUI's `.font()` modifiers:

```
Display      .system(.largeTitle, design: .rounded, weight: .bold)     // 34pt — currency totals
Title 1      .system(.title, design: .rounded, weight: .semibold)      // 28pt — screen titles
Title 2      .system(.title2, weight: .semibold)                       // 22pt — section heads
Body         .system(.body, weight: .regular)                          // 17pt — primary text
Callout      .system(.callout, weight: .medium)                        // 16pt — buttons, labels
Footnote     .system(.footnote, weight: .regular)                      // 13pt — meta info
Caption      .system(.caption2, weight: .medium)                       // 11pt — micro labels
```

Use `.rounded` design for *numbers and headlines only* — it gives the premium-fintech feel without being precious about body text.

### Spacing scale (use exclusively)
`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 56 · 80`

### Corner radii
- Cards: `16pt`
- Buttons (primary): `14pt`
- Modals/sheets: system default
- Icons/logos: `10pt` (subscription cards), `8pt` (small)

---

## 4 · Feature Inventory (Web → iOS Mapping)

Mark each as P0 (must ship v1), P1 (fast-follow), P2 (later).

| # | Feature | Priority | iOS Implementation Note |
|---|---|---|---|
| 1 | Email/password auth | **P0** | Supabase Auth + Sign in with Apple |
| 2 | Email verification gate | **P0** | Magic-link via Supabase; deep link back into app |
| 3 | Password reset | **P0** | Supabase reset flow with universal link |
| 4 | Subscription CRUD | **P0** | Add/edit/delete with swipe actions + context menu |
| 5 | Duplicate detection | **P0** | Client-side hash check before insert |
| 6 | Multi-currency (20+) | **P0** | Live rates cached 24h in `UserDefaults` + fallback table |
| 7 | Dashboard (stats + list) | **P0** | Large title nav, sticky stats card, sectioned list |
| 8 | Renewal notifications | **P0** | `UNUserNotificationCenter` local notifs, 3-day window |
| 9 | Service catalog ("Discover") | **P0** | 50+ services with brand colors, instant-add |
| 10 | Theme (light/dark/system) | **P0** | Bound to `@AppStorage("colorScheme")` |
| 11 | Localization (EN + TR) | **P0** | `Localizable.xcstrings` catalog |
| 12 | Analytics dashboard | **P0** | Native Charts framework (iOS 16+) |
| 13 | Category breakdown | **P0** | Donut chart + sorted list |
| 14 | AI insights (Gemini) | **P1** | Pro-only, sheet UI; same prompt as web |
| 15 | AI assistant chat | **P1** | Pro-only, native chat UI with `TextField` + streaming |
| 16 | Global price comparison | **P1** | Pro-only; lookup against catalog medians |
| 17 | Budget alerts per category | **P1** | Threshold notification when category > limit |
| 18 | CSV export | **P1** | Share sheet with generated CSV |
| 19 | CSV import | **P2** | Document picker → preview → bulk insert |
| 20 | Savings goal tracker | **P1** | Settings screen with progress ring |
| 21 | Achievements/badges | **P2** | Profile screen; subtle gamification |
| 22 | Friends / social sharing | **P2** | Defer to v2 |
| 23 | Calendar view | **P1** | `MultiDatePicker`-style with renewal markers |
| 24 | Onboarding tour | **P0** | 3-screen paged intro on first launch |
| 25 | Stripe billing | **P0** | Replaced by **StoreKit 2** (Apple IAP) — required by App Store rules |
| 26 | Account deletion | **P0** | Required by App Store guideline 5.1.1(v) |
| 27 | Sign in with Apple | **P0** | Required if any third-party social login present |
| 28 | Home Screen Widget | **P1** | Small/medium widget: monthly spend + next renewal |
| 29 | Lock Screen Widget | **P2** | Single circular: days until next renewal |
| 30 | Live Activity | **P2** | Show countdown to next renewal in Dynamic Island |
| 31 | Siri Shortcuts | **P2** | "Add subscription", "What's my monthly spend?" |
| 32 | App Intents | **P2** | Expose actions to Spotlight & Shortcuts app |
| 33 | iCloud Sync | **N/A** | Supabase is the source of truth; no CloudKit |

---

## 5 · Backend — Supabase

### 5.1 Project setup

1. Create project at `supabase.com` — region close to user base (Frankfurt for EU/TR)
2. Enable **Email auth** + **Apple OAuth**
3. Set up custom SMTP (SendGrid or Resend) for branded verification emails
4. Generate iOS anon key — store in `Config.plist` (not committed)

### 5.2 Database schema

Run all of this in the Supabase SQL editor as a single migration.

```sql
-- ────────────────────────────────────────────────────────────────
-- USER PROFILES (extends auth.users)
-- ────────────────────────────────────────────────────────────────
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  email           text not null,
  display_name    text,
  avatar_url      text,
  base_currency   text not null default 'USD',
  preferred_lang  text not null default 'en' check (preferred_lang in ('en','tr')),
  region          text not null default 'US',
  theme_pref      text not null default 'system' check (theme_pref in ('light','dark','system')),
  analytics_opt_out boolean not null default false,
  terms_accepted_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index on public.profiles (email);

-- ────────────────────────────────────────────────────────────────
-- SUBSCRIPTIONS
-- ────────────────────────────────────────────────────────────────
create table public.subscriptions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,

  -- Service identity
  name            text not null,
  category        text not null default 'Other',
  service_type    text,                       -- e.g. "Streaming", "SaaS"
  logo_url        text,                       -- optional override
  brand_color     text,                       -- hex, optional override

  -- Pricing
  price           numeric(12,2) not null check (price >= 0),
  currency        text not null default 'USD',
  cycle           text not null check (cycle in ('Monthly','Yearly')),

  -- Dates
  start_date      date,
  next_date       date not null,
  trial_end_date  date,
  billing_day     int check (billing_day between 1 and 31),

  -- Status & metadata
  status          text not null default 'Active'
                  check (status in ('Active','Trial','Expiring','Inactive')),
  nickname        text,
  notes           text,
  reminder_enabled boolean not null default true,

  -- Audit
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index on public.subscriptions (user_id);
create index on public.subscriptions (user_id, next_date);
create index on public.subscriptions (user_id, status);

-- Prevent duplicates
create unique index subscriptions_unique_per_user
  on public.subscriptions (user_id, lower(name), currency, price, cycle)
  where status != 'Inactive';

-- ────────────────────────────────────────────────────────────────
-- PAYMENT HISTORY (one row per charge)
-- ────────────────────────────────────────────────────────────────
create table public.payment_history (
  id              uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,
  amount          numeric(12,2) not null,
  currency        text not null,
  paid_on         date not null,
  created_at      timestamptz not null default now()
);

create index on public.payment_history (subscription_id);
create index on public.payment_history (user_id, paid_on desc);

-- ────────────────────────────────────────────────────────────────
-- BUDGETS (per category, monthly limit)
-- ────────────────────────────────────────────────────────────────
create table public.budgets (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  category        text not null,
  monthly_limit   numeric(12,2) not null check (monthly_limit > 0),
  currency        text not null default 'USD',
  created_at      timestamptz not null default now(),
  unique(user_id, category)
);

-- ────────────────────────────────────────────────────────────────
-- USER PLAN (replaces Stripe; tracked from StoreKit receipts)
-- ────────────────────────────────────────────────────────────────
create table public.user_plans (
  user_id              uuid primary key references auth.users(id) on delete cascade,
  tier                 text not null default 'free' check (tier in ('free','pro')),
  status               text not null default 'active'
                       check (status in ('active','trial','expired','grace_period','revoked')),
  product_id           text,                   -- StoreKit product ID
  original_transaction_id text,                -- for entitlement verification
  purchased_at         timestamptz,
  expires_at           timestamptz,
  auto_renew           boolean,
  updated_at           timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────────
-- AI INSIGHTS CACHE
-- ────────────────────────────────────────────────────────────────
create table public.ai_insights (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  insight_type    text not null,                -- 'redundancy' | 'cycle_swap'
  title           text not null,
  description     text not null,
  estimated_savings numeric(12,2),
  related_sub_ids uuid[],
  generated_at    timestamptz not null default now(),
  dismissed       boolean not null default false
);

create index on public.ai_insights (user_id, generated_at desc);

-- ────────────────────────────────────────────────────────────────
-- DEVICES (for push notifications)
-- ────────────────────────────────────────────────────────────────
create table public.devices (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  apns_token      text not null,
  device_name     text,
  app_version     text,
  os_version      text,
  last_seen_at    timestamptz not null default now(),
  unique(user_id, apns_token)
);
```

### 5.3 Row Level Security (REQUIRED)

```sql
-- Enable RLS on every table
alter table public.profiles         enable row level security;
alter table public.subscriptions    enable row level security;
alter table public.payment_history  enable row level security;
alter table public.budgets          enable row level security;
alter table public.user_plans       enable row level security;
alter table public.ai_insights      enable row level security;
alter table public.devices          enable row level security;

-- Generic policy template: users see/modify only their own rows
create policy "own_profile_read"   on profiles        for select using (auth.uid() = id);
create policy "own_profile_write"  on profiles        for update using (auth.uid() = id);

create policy "own_subs_all"       on subscriptions   for all    using (auth.uid() = user_id);
create policy "own_history_all"    on payment_history for all    using (auth.uid() = user_id);
create policy "own_budgets_all"    on budgets         for all    using (auth.uid() = user_id);
create policy "own_plan_read"      on user_plans      for select using (auth.uid() = user_id);
create policy "own_insights_all"   on ai_insights     for all    using (auth.uid() = user_id);
create policy "own_devices_all"    on devices         for all    using (auth.uid() = user_id);

-- user_plans is INSERT/UPDATE only by service role (StoreKit webhook)
-- No client-side write policy on user_plans
```

### 5.4 Database triggers

```sql
-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)));
  insert into public.user_plans (user_id) values (new.id);
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-touch updated_at
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

create trigger touch_subs   before update on subscriptions  for each row execute procedure touch_updated_at();
create trigger touch_profile before update on profiles      for each row execute procedure touch_updated_at();
```

### 5.5 Edge Functions

Three Deno edge functions to deploy via Supabase CLI:

**`ai-insights`** — Proxies Gemini API calls (so the API key never ships to clients).
```
POST /functions/v1/ai-insights
Body: { subscriptions: [...], baseCurrency, language }
Response: { insights: [...] }
```

**`storekit-notifications`** — Receives App Store Server Notifications V2 webhooks; updates `user_plans` table on purchase/renew/cancel/refund.
```
POST /functions/v1/storekit-notifications
```

**`exchange-rates`** — Caches Open Exchange Rates daily into a `kv_cache` table to avoid client-side rate limits.
```
GET /functions/v1/exchange-rates
Response: { base: 'USD', rates: {...}, updated_at: '...' }
```

### 5.6 Storage buckets

- `avatars` (public read, user-write own): profile photos
- `service-logos` (public read, admin-write): override logos for catalog services

---

## 6 · iOS Project Scaffold

### 6.1 Tech stack (locked)

| Layer | Choice | Why |
|---|---|---|
| Language | **Swift 5.10+** | Concurrency, macros, typed throws |
| UI | **SwiftUI 6** (iOS 17 min) | Charts, Observable, sensoryFeedback |
| Backend SDK | **supabase-swift** | First-party, async/await native |
| Networking | URLSession + async/await | No third-party needed |
| Persistence | **SwiftData** (cache only) | Source of truth = Supabase |
| Charts | **Swift Charts** | Native, accessible, animated |
| IAP | **StoreKit 2** | Required by Apple |
| Push | **UserNotifications** (local) + APNs (remote) | Both used |
| Widgets | **WidgetKit** | Home + Lock Screen |
| Live Activities | **ActivityKit** | Dynamic Island countdowns |
| Image loading | **AsyncImage** (built-in) | Sufficient for v1 |
| Linting | SwiftLint via SPM plugin | Enforced in CI |
| Min iOS | **iOS 17.0** | Cuts pre-A12 devices; enables all modern APIs |

### 6.2 Folder structure

```
SubSenseiOS/
├── App/
│   ├── SubSenseApp.swift              ← @main entry
│   ├── AppDelegate.swift              ← APNs registration
│   └── Config/
│       ├── Config.plist               ← anon key, env (gitignored)
│       └── Secrets.swift              ← typed accessor
│
├── Core/
│   ├── Auth/
│   │   ├── AuthService.swift          ← Supabase auth wrapper
│   │   ├── AuthStore.swift            ← @Observable session state
│   │   └── KeychainManager.swift
│   ├── Networking/
│   │   ├── SupabaseClient+Shared.swift
│   │   └── APIError.swift
│   ├── Data/
│   │   ├── Models/
│   │   │   ├── Subscription.swift
│   │   │   ├── Profile.swift
│   │   │   ├── Budget.swift
│   │   │   ├── UserPlan.swift
│   │   │   └── AIInsight.swift
│   │   ├── Repositories/
│   │   │   ├── SubscriptionRepository.swift
│   │   │   ├── ProfileRepository.swift
│   │   │   └── BudgetRepository.swift
│   │   └── Cache/
│   │       └── SwiftDataStack.swift
│   ├── Currency/
│   │   ├── CurrencyService.swift      ← rates fetch + convert
│   │   └── Currencies.swift           ← static metadata
│   ├── Notifications/
│   │   ├── LocalNotificationService.swift
│   │   └── RenewalScheduler.swift
│   ├── IAP/
│   │   ├── StoreKitService.swift
│   │   └── Products.swift
│   ├── AI/
│   │   ├── InsightsService.swift      ← calls edge function
│   │   └── AssistantService.swift     ← streaming chat
│   └── Localization/
│       └── L10n.swift                 ← generated string keys
│
├── Design/
│   ├── Theme/
│   │   ├── AppColor.swift
│   │   ├── AppFont.swift
│   │   ├── AppSpacing.swift
│   │   └── AppRadius.swift
│   ├── Components/                    ← reusable atoms
│   │   ├── GlassCard.swift
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── BrandIcon.swift            ← service logo bubble
│   │   ├── CurrencyPicker.swift
│   │   ├── EmptyState.swift
│   │   ├── SectionHeader.swift
│   │   └── StatChip.swift
│   └── Modifiers/
│       ├── GlassBackground.swift
│       ├── BrandHalo.swift
│       └── ShimmerOnLoad.swift
│
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── OnboardingViewModel.swift
│   ├── Auth/
│   │   ├── SignInView.swift
│   │   ├── SignUpView.swift
│   │   ├── VerifyEmailView.swift
│   │   └── ResetPasswordView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── DashboardViewModel.swift
│   │   ├── StatsCardView.swift
│   │   └── UpcomingRenewalsView.swift
│   ├── Subscriptions/
│   │   ├── SubscriptionListView.swift
│   │   ├── SubscriptionRowView.swift
│   │   ├── SubscriptionDetailView.swift
│   │   ├── AddSubscriptionView.swift
│   │   ├── EditSubscriptionView.swift
│   │   └── ServiceCatalogView.swift    ← "Discover"
│   ├── Analytics/
│   │   ├── AnalyticsView.swift
│   │   ├── SpendChartView.swift
│   │   ├── CategoryDonutView.swift
│   │   └── BudgetTrackerView.swift
│   ├── Calendar/
│   │   └── RenewalCalendarView.swift
│   ├── AI/
│   │   ├── InsightsView.swift
│   │   └── AssistantChatView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── EditProfileView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── CurrencySettingsView.swift
│   │   ├── LanguageSettingsView.swift
│   │   ├── ThemeSettingsView.swift
│   │   ├── NotificationSettingsView.swift
│   │   └── DangerZoneView.swift         ← delete account
│   └── Paywall/
│       └── PaywallView.swift
│
├── Widgets/
│   ├── SubSenseWidgetBundle.swift
│   ├── MonthlySpendWidget.swift        ← small + medium
│   ├── NextRenewalWidget.swift         ← small + lock screen
│   └── Provider/
│       └── TimelineProvider.swift
│
├── LiveActivities/
│   └── RenewalCountdownActivity.swift
│
├── Intents/                            ← App Intents for Siri/Shortcuts
│   ├── AddSubscriptionIntent.swift
│   └── MonthlySpendIntent.swift
│
└── Resources/
    ├── Assets.xcassets                 ← app icon, brand colors
    ├── Localizable.xcstrings           ← EN + TR
    └── ServiceCatalog.json             ← seeded popular services
```

### 6.3 Dependencies (`Package.swift`)

```swift
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
.package(url: "https://github.com/realm/SwiftLint", from: "0.55.0"),
```

That's it. **No third-party UI kits, no Alamofire, no Kingfisher.** Apple's frameworks cover everything.

---

## 7 · Core Data Models (Swift)

```swift
// MARK: - Subscription
struct Subscription: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    var category: Category
    var serviceType: String?
    var logoURL: URL?
    var brandColor: String?         // hex like "#E50914"
    var price: Decimal
    var currency: String
    var cycle: Cycle
    var startDate: Date?
    var nextDate: Date
    var trialEndDate: Date?
    var billingDay: Int?
    var status: Status
    var nickname: String?
    var notes: String?
    var reminderEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    enum Cycle: String, Codable, CaseIterable { case monthly = "Monthly", yearly = "Yearly" }
    enum Status: String, Codable, CaseIterable {
        case active = "Active", trial = "Trial", expiring = "Expiring", inactive = "Inactive"
    }
    enum Category: String, Codable, CaseIterable {
        case entertainment, music, gaming, design, ai, productivity, business,
             shopping, storage, fitness, news, education, other

        var displayName: String { /* localized */ }
        var symbol: String { /* SF Symbol per category */ }
    }

    /// Derived: monthly equivalent in original currency
    var monthlyEquivalent: Decimal {
        cycle == .yearly ? price / 12 : price
    }
}

// MARK: - Profile
struct Profile: Identifiable, Codable {
    let id: UUID
    var email: String
    var displayName: String?
    var avatarURL: URL?
    var baseCurrency: String
    var preferredLanguage: Language
    var region: String
    var themePref: ThemePref
    var analyticsOptOut: Bool

    enum Language: String, Codable { case en, tr }
    enum ThemePref: String, Codable { case light, dark, system }
}

// MARK: - User Plan
struct UserPlan: Codable {
    let userId: UUID
    var tier: Tier
    var status: Status
    var productId: String?
    var expiresAt: Date?
    var autoRenew: Bool?

    enum Tier: String, Codable { case free, pro }
    enum Status: String, Codable { case active, trial, expired, gracePeriod = "grace_period", revoked }

    var isPro: Bool { tier == .pro && (status == .active || status == .trial || status == .gracePeriod) }
}

// MARK: - AI Insight
struct AIInsight: Identifiable, Codable {
    let id: UUID
    var type: InsightType
    var title: String
    var description: String
    var estimatedSavings: Decimal?
    var relatedSubIds: [UUID]
    var generatedAt: Date
    var dismissed: Bool

    enum InsightType: String, Codable { case redundancy, cycleSwap = "cycle_swap" }
}
```

---

## 8 · Screen Specifications

Below: every screen, top to bottom, with layout, components, and behavior. Build in this order.

### 8.1 Launch & Onboarding

**`OnboardingView`** — Shown only on first launch (`@AppStorage("hasSeenOnboarding")`).

3 paged screens with `TabView(.page)`:

```
┌──────────────────────────────────────┐
│                                      │
│        [glowing logo mark]           │
│                                      │
│      See every subscription          │
│           in one place.              │
│                                      │
│   Netflix, Spotify, ChatGPT, gym…    │
│   never lose track of what you pay.  │
│                                      │
│                                      │
│           ● ○ ○                      │
│                                      │
│      ┌──────────────────────┐        │
│      │      Continue        │        │
│      └──────────────────────┘        │
│                                      │
└──────────────────────────────────────┘
```

- Screen 1: "See every subscription" — illustration of stacked cards floating
- Screen 2: "AI that saves you money" — Pro teaser
- Screen 3: "Multi-currency, multi-lingual" — currency flags fan
- Final CTA: `Continue with Apple` (primary) + `Sign in with email` (secondary)

### 8.2 Auth flow

**`SignInView` / `SignUpView`** — Sheet presented modally from onboarding or unauthenticated launch.

Layout:
- Top: large rounded title "Welcome back" / "Create your account"
- `TextField` for email — `.textContentType(.emailAddress)`, `.keyboardType(.emailAddress)`, `.textInputAutocapitalization(.never)`
- `SecureField` for password with eye toggle
- Primary button "Sign in" / "Create account"
- Divider with "or"
- `SignInWithAppleButton` (full width, `.continue`, matches color scheme)
- Below: "Forgot password?" / Switch to sign up

**`VerifyEmailView`** — Shown when user signs in but email not confirmed.

```
┌──────────────────────────────────────┐
│                                      │
│         ✉ envelope.badge symbol      │
│                                      │
│       Verify your email              │
│                                      │
│   We sent a magic link to            │
│   you@example.com                    │
│                                      │
│   Tap the link in the email,         │
│   then come back here.               │
│                                      │
│   ┌──────────────────────────┐       │
│   │  I've verified — refresh │       │
│   └──────────────────────────┘       │
│                                      │
│   [Resend email]   [Use a different  │
│                     account]         │
└──────────────────────────────────────┘
```

Universal link `https://subsense.app/verify?token=...` routes back into app and calls `supabase.auth.exchangeCodeForSession()`.

### 8.3 Dashboard (main screen)

**`DashboardView`** — Root tab after auth. The first impression.

```
┌──────────────────────────────────────┐
│  Home                       👤       │  ← Large nav title; avatar trailing
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │  THIS MONTH                    │  │
│  │                                │  │
│  │  $142.50                       │  │  ← Display font, 34pt rounded bold
│  │  ↑ $12 vs last month           │  │  ← muted footnote
│  │                                │  │
│  │  ─────────────────────         │  │
│  │  12 active   ·  $1,710/yr      │  │
│  └────────────────────────────────┘  │  ← Glass card, brand-tinted halo
│                                      │
│  UP NEXT                             │  ← Section header
│                                      │
│  ┌────────────────────────────────┐  │
│  │ 🔴 Netflix         in 2 days   │  │
│  │    $15.99 · Monthly            │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 🟢 Spotify         in 5 days   │  │
│  │    $9.99 · Monthly             │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 🟡 ChatGPT Plus    in 11 days  │  │
│  │    $20 · Monthly               │  │
│  └────────────────────────────────┘  │
│                                      │
│  [   See all 12 subscriptions →  ]   │
│                                      │
│  ✨  AI INSIGHT             [Pro]    │  ← if Pro, full card; else teaser
│  ┌────────────────────────────────┐  │
│  │  You have 3 streaming services │  │
│  │  totaling $44/mo. Switching    │  │
│  │  Netflix to yearly saves $24/yr│  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
   [ Home ] [ List ] [ + ] [ Stats ] [ ⚙ ]    ← TabView w/ center FAB
```

**Behavior:**
- Pull to refresh → re-fetches subs + rates
- Tap stats card → expands to year/lifetime view
- Tap renewal row → opens `SubscriptionDetailView` as sheet
- Center "+" tab pushes `AddSubscriptionView` sheet (`.large` detent)
- Long-press on renewal → context menu: "Snooze 1 day", "Mark as paid", "Edit"

### 8.4 Subscription list

**`SubscriptionListView`** — Second tab. Pure list view, all subs sectioned.

```
┌──────────────────────────────────────┐
│  Subscriptions          ⌕  ⊕         │
├──────────────────────────────────────┤
│  [All] [Active] [Trial] [Inactive]   │  ← Segmented control
│                                      │
│  ACTIVE — 12                         │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ N  Netflix          $15.99   │    │
│  │    Streaming  ·  in 2 days   │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ S  Spotify           $9.99   │    │
│  │    Music  ·  in 5 days       │    │
│  └──────────────────────────────┘    │
│                                      │
│  TRIAL — 1                           │
│  ┌──────────────────────────────┐    │
│  │ A  Apple TV+         FREE    │    │
│  │    Trial ends in 4 days      │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Row:** brand-color circle with first letter (or actual logo if available), name, price right-aligned, category + next renewal in muted footnote.

**Interactions:**
- Swipe left → Delete (red, requires confirmation)
- Swipe right → Mark inactive (gray)
- Tap → push detail
- Context menu (long press): Edit, Duplicate, Share, Mark inactive, Delete

### 8.5 Add / Edit subscription

**`AddSubscriptionView`** — Sheet, `.large` detent, `.dragIndicator(.visible)`.

```
┌──────────────────────────────────────┐
│  Cancel       Add Sub          Save  │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Pick from popular services    │  │  ← horizontal scroll
│  │  [N] [S] [Y] [+] [D] [G] [A]   │  │  ← brand bubbles
│  └────────────────────────────────┘  │
│                                      │
│  NAME                                │
│  ┌────────────────────────────────┐  │
│  │ Netflix                        │  │
│  └────────────────────────────────┘  │
│                                      │
│  CATEGORY                            │
│  ┌────────────────────────────────┐  │
│  │ 🎬 Entertainment           ›   │  │  ← Menu picker
│  └────────────────────────────────┘  │
│                                      │
│  PRICE                               │
│  ┌──────────────┬─────────────────┐  │
│  │ $   15.99    │  USD   ›        │  │  ← TextField + currency picker
│  └──────────────┴─────────────────┘  │
│                                      │
│  CYCLE                               │
│  [  Monthly  ]  [  Yearly  ]         │  ← segmented
│                                      │
│  NEXT BILLING DATE                   │
│  ┌────────────────────────────────┐  │
│  │ Dec 28, 2026             📅    │  │
│  └────────────────────────────────┘  │
│                                      │
│  REMIND ME                           │
│  ┌────────────────────────────────┐  │
│  │ 3 days before renewal      [●] │  │  ← toggle
│  └────────────────────────────────┘  │
│                                      │
│  NOTES (optional)                    │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

**Validation rules:**
- Name: required, max 50 chars
- Price: required, > 0, max 2 decimals
- Duplicate check: if same name+currency+price+cycle exists, show `DuplicateAlert` with "Add anyway / Cancel"
- Save: haptic success + dismiss + new row animates into list

### 8.6 Subscription detail

**`SubscriptionDetailView`** — Push or sheet (`.medium` then `.large` on scroll).

```
┌──────────────────────────────────────┐
│  ‹ Back                       ···    │
├──────────────────────────────────────┤
│                                      │
│        ┌────────────────┐            │
│        │       N        │            │  ← Big brand-color circle, 80pt
│        └────────────────┘            │
│                                      │
│            Netflix                    │  ← Title 1
│         Entertainment                 │  ← caption muted
│                                      │
│  ┌────────────────────────────────┐  │
│  │  $15.99 / month                │  │
│  │  $191.88 per year              │  │
│  │  Next charge: Dec 28           │  │
│  └────────────────────────────────┘  │
│                                      │
│  STATS                               │
│  ┌──────────┬──────────┬──────────┐  │
│  │  $192    │   12     │  $2,304  │  │
│  │ This yr  │  Months  │ Lifetime │  │
│  └──────────┴──────────┴──────────┘  │
│                                      │
│  RENEWAL HISTORY                     │
│   • Nov 28 — $15.99                  │
│   • Oct 28 — $15.99                  │
│   • Sep 28 — $13.99 (price changed)  │
│                                      │
│  ┌──────────────────────────────┐    │
│  │       Edit subscription      │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │       Mark as inactive       │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │           Delete             │    │  ← destructive red
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

### 8.7 Discover / Service catalog

**`ServiceCatalogView`** — Triggered from the "Pick popular service" row in Add screen, or its own entry from the "+" tab.

Sectioned grid of ~50 services, by category. Tap a service → pre-filled `AddSubscriptionView` with name, category, default price for user's region, brand color, logo.

Source: `ServiceCatalog.json` bundled with app (seed list below). Editable via OTA Supabase fetch.

```
┌──────────────────────────────────────┐
│  ‹  Discover services        ⌕       │
├──────────────────────────────────────┤
│                                      │
│  ENTERTAINMENT                       │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                 │
│  │N │ │D+│ │H │ │P+│                 │  ← 2x grid of brand bubbles
│  └──┘ └──┘ └──┘ └──┘                 │
│  Netflix  Disney+  HBO   Para+       │
│                                      │
│  MUSIC                               │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                 │
│  │S │ │AM│ │T │ │D │                 │
│  └──┘ └──┘ └──┘ └──┘                 │
│  Spotify Apple   Tidal  Deezer       │
│                                      │
│  AI                                  │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                 │
│  │C │ │Cl│ │G │ │P │                 │
│  └──┘ └──┘ └──┘ └──┘                 │
│  ChatGPT Claude Gemini Perplx        │
│                                      │
│  …                                   │
└──────────────────────────────────────┘
```

### 8.8 Analytics

**`AnalyticsView`** — Fourth tab. Heavy use of Swift Charts.

```
┌──────────────────────────────────────┐
│  Insights                            │
├──────────────────────────────────────┤
│  [30d] [3m] [6m] [12m]               │  ← time range picker
│                                      │
│  SPENDING TREND                      │
│  ┌────────────────────────────────┐  │
│  │  $       ╱╲                    │  │
│  │   $    ╱    ╲___    ╱╲         │  │  ← LineChart, smoothed
│  │    $ ╱           ╲╱            │  │
│  │     ─────────────────          │  │
│  │     M  J  J  A  S  O  N  D     │  │
│  └────────────────────────────────┘  │
│                                      │
│  BY CATEGORY                         │
│  ┌────────────────────────────────┐  │
│  │       ╭─────╮                  │  │
│  │      ╱       ╲   Entertainment │  │
│  │     │         │  42%  $61      │  │  ← Donut chart + legend
│  │      ╲       ╱   Music         │  │
│  │       ╰─────╯    18%  $26      │  │
│  │                  AI            │  │
│  │                  12%  $17      │  │
│  └────────────────────────────────┘  │
│                                      │
│  TOP SERVICES                        │
│  Netflix          ████████  $192/yr  │
│  ChatGPT          ██████    $240/yr  │
│  Spotify          ████      $120/yr  │
│  Adobe CC         ███       $660/yr  │
│                                      │
│  BUDGETS                             │
│  Entertainment  ██████░  $42/$50     │  ← progress bar
│  Productivity   ██████████  $130/$100│  ← over budget, red
│                                      │
└──────────────────────────────────────┘
```

### 8.9 Calendar view

**`RenewalCalendarView`** — Sub-view inside Analytics or its own entry.

Month-grid calendar (use `MultiDatePicker`-style custom view). Days with renewals show colored dot under the date matching the dominant brand color of that day's renewals. Tap a day → bottom sheet listing subs renewing that day.

### 8.10 AI Insights & Assistant

**`InsightsView`** (Pro only, paywall for Free)

```
┌──────────────────────────────────────┐
│  ‹ AI Insights                       │
├──────────────────────────────────────┤
│                                      │
│  Powered by Gemini · 2 found         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ 💡 Switch to yearly billing    │  │
│  │                                │  │
│  │ Netflix charged monthly is     │  │
│  │ $191/yr. The annual plan saves │  │
│  │ you ~$24/year.                 │  │
│  │                                │  │
│  │ Estimated savings: $24/year    │  │
│  │                                │  │
│  │ [ Open Netflix's site ]        │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ ⚠ Redundant services           │  │
│  │                                │  │
│  │ You have ChatGPT Plus, Claude  │  │
│  │ Pro, and Gemini Advanced. Most │  │
│  │ users find one is enough.      │  │
│  │                                │  │
│  │ Cancelling 2 saves: ~$40/mo    │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ✨ Ask the assistant         ›│  │  ← opens AssistantChatView
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**`AssistantChatView`** — Native chat UI. User can ask: "Which sub gives me the worst value?", "How much will I spend this year?", "What can I cut to save $50/mo?". Streams Gemini responses sentence-by-sentence using `AsyncStream`.

### 8.11 Settings

**`SettingsView`** — Fifth tab. Standard iOS settings list (`Form` / `List` with sections).

```
┌──────────────────────────────────────┐
│  Settings                            │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │ 👤  Kutluhan Gil               │  │
│  │     kutluhangul@windowslive    │  │
│  │     [ Free ]            Edit › │  │
│  └────────────────────────────────┘  │
│                                      │
│  PREFERENCES                         │
│  ⊕  Currency                USD ›    │
│  🌐  Language          English ›     │
│  🎨  Appearance         System ›     │
│  🔔  Notifications              ›    │
│                                      │
│  PLAN                                │
│  ✨  SubSense Pro          Upgrade › │
│  📥  Restore purchases           ›   │
│                                      │
│  DATA                                │
│  📤  Export as CSV               ›   │
│  📥  Import from CSV             ›   │
│                                      │
│  SUPPORT                             │
│  📖  Help Center                 ›   │
│  ✉   Contact support             ›   │
│  ⭐  Rate on the App Store        ›  │
│                                      │
│  LEGAL                               │
│  📄  Privacy Policy              ›   │
│  📄  Terms of Service            ›   │
│                                      │
│  ACCOUNT                             │
│  🚪  Sign out                        │
│  ⚠   Delete account                  │  ← red, opens DangerZone
│                                      │
│  SubSense 1.0 · build 1              │
└──────────────────────────────────────┘
```

**`DangerZoneView`** — Required by App Store Review:
- 2-step confirmation: typed "DELETE" then Face ID
- Calls `supabase.auth.admin.deleteUser()` via edge function
- Cascades to all `user_id` tables (already set with `on delete cascade`)

### 8.12 Paywall

**`PaywallView`** — Triggered when Free user taps any Pro feature.

```
┌──────────────────────────────────────┐
│                                ✕     │
│                                      │
│         ✨                            │
│                                      │
│      Unlock SubSense Pro             │
│                                      │
│   Smart insights, AI assistant,      │
│   and price comparison.              │
│                                      │
│   ✓ AI savings recommendations       │
│   ✓ Unlimited Gemini chat            │
│   ✓ Global price comparison          │
│   ✓ Priority support                 │
│                                      │
│   ┌──────────────────────────────┐   │
│   │  Yearly       $29.99/yr      │   │  ← featured, badge "Save 37%"
│   │              $2.50/month     │   │
│   └──────────────────────────────┘   │
│   ┌──────────────────────────────┐   │
│   │  Monthly       $3.99/mo      │   │
│   └──────────────────────────────┘   │
│                                      │
│   ┌──────────────────────────────┐   │
│   │   Start 7-day free trial     │   │
│   └──────────────────────────────┘   │
│                                      │
│   Restore purchases · Terms · Privacy│
└──────────────────────────────────────┘
```

Use StoreKit 2 `Product.purchase()`. On success, edge function `storekit-notifications` flips `user_plans.tier` to `pro`.

---

## 9 · Animations & Micro-interactions

Every transition matters. Specific rules:

| Trigger | Animation | Haptic |
|---|---|---|
| Tap any button | `.scaleEffect(0.97)` on press, spring back | `.impact(.soft)` |
| Add subscription saved | Row slides in from top + 3px bounce | `.success` |
| Delete subscription | Row swipes out + collapse | `.impact(.medium)` |
| Switch tab | Cross-fade 200ms | None |
| Pull to refresh | Stretches stats card, releases with spring | `.impact(.soft)` on trigger |
| Currency conversion | Numbers `.contentTransition(.numericText())` | None |
| AI insight loads | Shimmer placeholder → fade-in | None |
| Pro purchase success | Confetti `.symbolEffect(.bounce)` on ✨ icon | `.success` (3 beats) |
| Long-press for context menu | Native scale + blur | iOS default |
| Renewal countdown < 24h | Pulse animation on the badge | None |

All numeric values use `.contentTransition(.numericText())` so currency changes animate digit-by-digit.

---

## 10 · Native iOS Polish

### 10.1 Home Screen Widgets

**MonthlySpendWidget (Small + Medium)**
- Small: just the monthly total + currency
- Medium: total + next 3 upcoming renewals with brand colors
- Timeline refreshes every 6 hours, also on app update via `WidgetCenter.shared.reloadAllTimelines()`

**NextRenewalWidget (Small + Lock Screen)**
- Small: brand logo + service name + days countdown
- Lock Screen circular: just the countdown number

### 10.2 Live Activities

**RenewalCountdownActivity**
- Auto-starts when any sub is renewing in ≤ 48h
- Shows in Dynamic Island: compact = brand logo + "2d"; expanded = full service info
- Auto-ends when renewal date passes or user dismisses

### 10.3 Siri Shortcuts / App Intents

```swift
struct AddSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Subscription"
    @Parameter(title: "Service name") var name: String
    @Parameter(title: "Price") var price: Double
    @Parameter(title: "Cycle") var cycle: CycleEnum

    func perform() async throws -> some IntentResult & ProvidesDialog { ... }
}

struct MonthlySpendIntent: AppIntent {
    static var title: LocalizedStringResource = "Get my monthly spend"
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView { ... }
}
```

Expose to Siri: "Hey Siri, what's my monthly spend?" → opens snippet with total.

### 10.4 Push notifications

**Local notifications** (no server needed):
- Scheduled at sub creation, 3 days before `next_date` at 9:00 AM user-local
- Cancelled & rescheduled on edit/delete
- Use `UNCalendarNotificationTrigger`

**Remote notifications** (for marketing, AI insights ready, plan status):
- Use Supabase + APNs through an edge function
- Device tokens stored in `devices` table

### 10.5 Sign in with Apple

```swift
SignInWithAppleButton(.continue) { request in
    request.requestedScopes = [.email, .fullName]
} onCompletion: { result in
    // Pass identity token to supabase.auth.signInWithIdToken()
}
.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
```

### 10.6 Universal Links

- `subsense.app/verify` → email verification
- `subsense.app/reset` → password reset
- `subsense.app/share/:id` → (v2) view shared subscription

Set up `apple-app-site-association` file on the domain.

### 10.7 Accessibility

Non-negotiables:
- All buttons have `.accessibilityLabel` (especially icon-only)
- All charts have `.accessibilityChartDescriptor`
- VoiceOver reads currency amounts as currency, not as numbers
- Support Dynamic Type from `xSmall` to `accessibility5`
- Color contrast: WCAG AA throughout (use `Color.semantic` tokens, not raw hex)
- Reduce Motion → swap spring animations for `.linear(duration: 0.15)`
- Reduce Transparency → swap glass for solid surfaces

---

## 11 · Localization (EN + TR)

Use Xcode's new `.xcstrings` String Catalog. Key namespaces:

```
auth.signIn.title              → "Welcome back" / "Tekrar hoş geldin"
auth.signUp.title              → "Create your account" / "Hesabını oluştur"
dashboard.thisMonth            → "This month" / "Bu ay"
dashboard.upNext               → "Up next" / "Yaklaşan"
subscription.cycle.monthly     → "Monthly" / "Aylık"
subscription.cycle.yearly      → "Yearly" / "Yıllık"
subscription.add.title         → "Add subscription" / "Abonelik ekle"
analytics.title                → "Insights" / "İstatistikler"
analytics.spending.trend       → "Spending trend" / "Harcama trendi"
settings.currency              → "Currency" / "Para birimi"
settings.deleteAccount         → "Delete account" / "Hesabı sil"
notifications.renewal          → "%@ renews in %d days" / "%@ %d gün sonra yenileniyor"
paywall.title                  → "Unlock SubSense Pro" / "SubSense Pro'ya yükselt"
paywall.feature.aiInsights     → "AI savings recommendations" / "AI tasarruf önerileri"
ai.assistant.placeholder       → "Ask anything about your subs…" / "Aboneliklerin hakkında sor…"
```

Numbers & currency: always use `Locale.current` aware formatters:
```swift
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = profile.baseCurrency
formatter.locale = profile.preferredLanguage == .tr ? Locale(identifier: "tr_TR") : Locale(identifier: "en_US")
```

Dates: use `Date.FormatStyle.relative(presentation: .named)` for "in 3 days" / "3 gün içinde".

---

## 12 · Service Catalog (seed)

Ship `Resources/ServiceCatalog.json` with at least these. Each entry:

```json
{
  "id": "netflix",
  "name": "Netflix",
  "category": "entertainment",
  "type": "Streaming",
  "brandColor": "#E50914",
  "logoSymbol": "play.tv.fill",
  "defaultPricing": {
    "US": { "currency": "USD", "monthly": 15.99, "yearly": null },
    "TR": { "currency": "TRY", "monthly": 229.99, "yearly": null }
  }
}
```

**Must include (50 services minimum):**

Entertainment: Netflix, Disney+, HBO Max, Hulu, Amazon Prime Video, Apple TV+, Paramount+, Peacock, YouTube Premium, Crunchyroll, BluTV, Exxen
Music: Spotify, Apple Music, Tidal, Deezer, Amazon Music, SoundCloud Go+, Audible
Gaming: Xbox Game Pass, PlayStation Plus, Nintendo Switch Online, EA Play, Ubisoft+, GeForce Now
AI: ChatGPT Plus, Claude Pro, Gemini Advanced, Perplexity Pro, GitHub Copilot, Midjourney
Design: Adobe Creative Cloud, Canva Pro, Figma Professional, Procreate
Productivity: Notion, Microsoft 365, Google Workspace, Slack Pro, Zoom Pro, Grammarly Premium
Shopping: Amazon Prime, Hepsiburada Premium, Trendyol Elite, Getir
Storage: iCloud+, Dropbox, Google One, OneDrive
Fitness/Health: Apple Fitness+, Strava, MyFitnessPal Premium
Education: Duolingo Plus, MasterClass, Coursera Plus

Each service comes with brand color, suggested icon (SF Symbol fallback), and default monthly price for US & TR regions.

---

## 13 · Pre-Launch Checklist

Before shipping to App Store:

### App functionality
- [ ] All P0 features working end-to-end
- [ ] Tested on iPhone SE (smallest screen) + iPhone Pro Max
- [ ] Tested on iPad (compact layouts adapt)
- [ ] Works offline — reads from SwiftData cache, queues writes
- [ ] No crash logs in 7 days of dogfooding

### Apple compliance
- [ ] Sign in with Apple present (required if any social login exists)
- [ ] Account deletion present and functional
- [ ] App Tracking Transparency prompt if analytics used
- [ ] Privacy nutrition labels filled in App Store Connect
- [ ] Privacy Policy + Terms URLs in Settings & paywall
- [ ] StoreKit configuration includes free trial language
- [ ] Restore purchases works
- [ ] No mentions of payment methods other than Apple IAP (in-app)

### Performance
- [ ] App cold start < 1.5s on iPhone 12
- [ ] Dashboard render with 50 subs < 500ms
- [ ] No main-thread work > 16ms
- [ ] App size < 50MB

### Visual QA
- [ ] Dark mode every screen
- [ ] Light mode every screen
- [ ] Dynamic Type at `xxxLarge` doesn't break layouts
- [ ] RTL mirroring (test with pseudo-language) works for future Arabic
- [ ] All animations respect Reduce Motion
- [ ] All glass surfaces have Reduce Transparency fallback

### Backend
- [ ] All Supabase tables have RLS enabled
- [ ] All edge functions have rate limiting
- [ ] Custom SMTP set up for branded emails
- [ ] APNs key uploaded to Supabase
- [ ] StoreKit notifications webhook verified with test purchases

### Localization
- [ ] All strings in `.xcstrings`, no hardcoded English
- [ ] TR translations reviewed by native speaker
- [ ] Numbers, dates, currency formatted per locale
- [ ] App Store listing translated (EN + TR)

### App Store assets
- [ ] App icon (1024×1024) + light/dark/tinted variants for iOS 18
- [ ] 5 screenshots per device class (iPhone 6.7", 6.1", 5.5", iPad 12.9")
- [ ] Preview video (optional but recommended)
- [ ] App description ≤ 4000 chars, subtitle ≤ 30 chars
- [ ] Keywords filled (100 chars)
- [ ] Promo text (170 chars) for updates

---

## 14 · Pricing & Monetization

**Two products in App Store Connect:**

| Product ID | Type | Price (US) | Price (TR) | Trial |
|---|---|---|---|---|
| `com.subsense.pro.monthly` | Auto-renewing subscription | $3.99/mo | ₺149/mo | 7 days |
| `com.subsense.pro.yearly` | Auto-renewing subscription | $29.99/yr | ₺899/yr | 7 days |

**Subscription group:** `SubSense Pro` (so users can switch monthly ↔ yearly within group).

**Free tier limits (intentionally generous to maximize organic growth):**
- Unlimited subscriptions
- Full analytics
- All currencies, all categories
- Local renewal notifications

**Pro unlocks:**
- AI insights (Gemini)
- AI chat assistant (unlimited messages)
- Global price comparison
- CSV import (free has export only)
- Priority email support badge
- Custom app icon (1 extra)

---

## 15 · Roadmap After v1

| When | What |
|---|---|
| v1.1 (1 month after launch) | CSV import, custom app icons, iPad-optimized layouts |
| v1.2 (2 months) | Apple Watch companion (next renewal complication) |
| v1.3 (3 months) | Family Sharing — share subs with up to 5 people |
| v2.0 (6 months) | Bank integration (Plaid US, Setu TR) for auto-detection of charges |
| v2.1 | Browser extension companion |
| v3.0 | macOS catalyst build |

---

## 16 · One-Shot Build Prompt

Paste this into Claude Code to scaffold the entire project:

```
Build a production-grade native iOS app named "SubSense" following the
specification in this document. Use SwiftUI 6, iOS 17 minimum, Swift 5.10+,
and Supabase as the backend. Implement features in priority order:

1. Scaffold Xcode project with folder structure from §6.2
2. Set up Supabase client + Auth (email/password + Sign in with Apple)
3. Apply database schema from §5.2 + RLS from §5.3 + triggers from §5.4
4. Implement design system (colors, fonts, spacing) from §3
5. Build screens in order: Onboarding → Auth → Dashboard → Subscription List
   → Add/Edit → Detail → Discover → Analytics → Settings → Paywall
6. Add local push notifications for renewal reminders (§10.4)
7. Add StoreKit 2 for Pro subscription (§14)
8. Add EN + TR localization (§11)
9. Add Home Screen widgets (§10.1)
10. Run pre-launch checklist (§13)

Follow these rules:
- No third-party UI libraries
- Source of truth = Supabase; cache locally in SwiftData
- Every screen must work in both light and dark mode
- All animations use spring(response: 0.4, dampingFraction: 0.8)
- Use SF Symbols only — no custom icons in v1
- Number changes animate via .contentTransition(.numericText())
- Haptic feedback on every meaningful interaction
- Pull to refresh, swipe actions, context menus everywhere they fit
- Accessibility labels on every interactive element
- Strict 4/8/12/16/20/24/32 spacing grid

Begin with the Supabase setup and project scaffold. Stop after each
major feature for review.
```

---

<div align="center">

**◈ End of Blueprint ◈**

*This document is complete. Everything needed to build SubSense iOS is above.*

*v1.0 · 2026-05-19*

</div>
