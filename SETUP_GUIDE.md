# SubSense iOS — Kurulum Rehberi

Bu rehber, projeyi derleyip App Store'a göndermeye hazır hale getirmek için elle yapman gereken adımları sırasıyla anlatır.

---

## İçindekiler

1. [Gereksinimler](#1-gereksinimler)
2. [Supabase Yapılandırması](#2-supabase-yapılandırması)
3. [Gemini API Anahtarı](#3-gemini-api-anahtarı)
4. [Config.plist Güncelleme](#4-configplist-güncelleme)
5. [Xcode Ayarları](#5-xcode-ayarları)
6. [App Store Connect — StoreKit Ürünleri](#6-app-store-connect--storekit-ürünleri)
7. [Widget App Group](#7-widget-app-group)
8. [Sign in with Apple](#8-sign-in-with-apple)
9. [Push Bildirimleri (APNs)](#9-push-bildirimleri-apns)
10. [Supabase Edge Functions](#10-supabase-edge-functions)
11. [Deep Link (Universal Links)](#11-deep-link-universal-links)
12. [İlk Derleme ve Test](#12-i̇lk-derleme-ve-test)
13. [App Store'a Gönderme](#13-app-storea-gönderme)

---

## 1. Gereksinimler

Başlamadan önce şunların hazır olduğundan emin ol:

| Araç | Versiyon | Nereden |
|---|---|---|
| Xcode | 15.4+ | Mac App Store |
| iOS Simulator | iOS 17.0+ | Xcode → Simulator |
| Apple Developer hesabı | Aktif ($99/yıl) | developer.apple.com |
| Supabase hesabı | Ücretsiz tier yeterli | supabase.com |
| Google AI Studio hesabı | Ücretsiz | aistudio.google.com |

---

## 2. Supabase Yapılandırması

Supabase projesi oluşturuldu (`jnnzbmkefhcvrlkgrxgv`, Frankfurt). Aşağıdaki ayarları **Supabase Dashboard** üzerinden yapman gerekiyor.

### 2.1 Email Auth + Apple OAuth Aktif Et

1. [supabase.com/dashboard](https://supabase.com/dashboard) → Projeyi aç
2. Sol menü: **Authentication → Providers**
3. **Email** satırında:
   - `Enable Email provider` → **ON**
   - `Confirm email` → **ON** *(doğrulama zorunlu olsun)*
   - `Secure email change` → **ON**
4. **Apple** satırında:
   - `Enable Apple provider` → **ON**
   - `Services ID`: `com.subsense.app.siwa` *(App Store Connect'ten alacaksın — §8'e bak)*
   - `Secret Key`: Apple'dan üreteceğin `.p8` dosyasının içeriği

### 2.2 Email Şablonlarını Özelleştir (Opsiyonel ama önerilen)

1. **Authentication → Email Templates**
2. **Confirm signup** şablonunu aç, `Redirect URL` kısmına yaz:
   ```
   https://subsense.app/verify
   ```
3. **Reset password** şablonunu aç, `Redirect URL`:
   ```
   https://subsense.app/reset
   ```

> Bu URL'leri daha sonra §11'de Universal Links ile bağlayacaksın.

### 2.3 Custom SMTP (Opsiyonel)

Supabase'in kendi SMTP'si günlük 3 mail ile sınırlı. Production için:

1. **Project Settings → Authentication → SMTP Settings**
2. [resend.com](https://resend.com) veya SendGrid'den SMTP credentials al
3. Alanları doldur: Host, Port, Kullanıcı adı, Şifre, Gönderen e-posta

### 2.4 Storage Bucket Oluştur

1. Sol menü: **Storage → New bucket**
2. Bucket adı: `avatars` — **Public** seç
3. Tekrar: **New bucket** → `service-logos` — **Public** seç

---

## 3. Gemini API Anahtarı

AI Insights ve Asistan özellikleri için Google Gemini API anahtarı gerekiyor.

1. [aistudio.google.com](https://aistudio.google.com) → **Get API key**
2. **Create API key** → Projeyi seç veya yeni proje oluştur
3. Anahtarı kopyala (bir sonraki adımda kullanacaksın)

> **Dikkat:** Bu anahtar uygulamaya gömülmez. Supabase edge function'a eklenir (§10'da anlatılıyor).

---

## 4. Config.plist Güncelleme

`SubSense/App/Config/Config.plist` dosyasını aç ve `GEMINI_API_KEY` alanını doldur:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist ...>
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://jnnzbmkefhcvrlkgrxgv.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</string>
    <key>GEMINI_API_KEY</key>
    <string>BURAYA_GEMINI_ANAHTARINI_YAZ</string>  <!-- ← değiştir -->
</dict>
</plist>
```

> `Config.plist` `.gitignore`'a ekli — asla commit'lenmiyor.

---

## 5. Xcode Ayarları

### 5.1 Projeyi Aç

```bash
cd /Volumes/ProjectVault/SubSense-IOS
open SubSense.xcodeproj
```

### 5.2 Development Team Seç

1. Sol panelde **SubSense** projesine tıkla
2. **TARGETS → SubSense → Signing & Capabilities**
3. `Team` açılır menüsünden kendi Apple Developer hesabını seç
4. Aynı işlemi **SubSenseWidgets** target'ı için de yap

### 5.3 Bundle ID Kontrol

Varsayılan bundle ID: `com.subsense.app`

Eğer bu ID başkası tarafından alınmışsa değiştirmen gerekir:
- **Project Settings → TARGETS → SubSense → Build Settings**
- `PRODUCT_BUNDLE_IDENTIFIER` → istediğin ID'yi yaz (ör. `com.senin-adin.subsense`)
- Widget: `com.senin-adin.subsense.widgets`

> Bundle ID'yi değiştirirsen `SubSense.entitlements` ve `SubSenseWidgets.entitlements` içindeki `App Groups` değerini de güncelle.

### 5.4 Swift Package Dependencies İndir

İlk açılışta Xcode otomatik indirir. Eğer indirmezse:
**File → Packages → Resolve Package Versions**

İndirilen paketler:
- `supabase-swift` 2.x
- `SwiftLint` 0.55.x

---

## 6. App Store Connect — StoreKit Ürünleri

Uygulamanın satın alma ekranının çalışması için bu adım şart.

### 6.1 App Oluştur

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps → +**
2. **New App**:
   - Platform: iOS
   - Name: `SubSense`
   - Bundle ID: `com.subsense.app` *(Xcode'dakiyle aynı olmalı)*
   - SKU: `subsense-ios`

### 6.2 Subscription Group Oluştur

1. App sayfasında sol menü: **Subscriptions → +**
2. **Create Subscription Group**:
   - Reference Name: `SubSense Pro`
3. Gruba iki ürün ekle:

**Ürün 1 — Aylık:**
| Alan | Değer |
|---|---|
| Reference Name | SubSense Pro Monthly |
| Product ID | `com.subsense.pro.monthly` |
| Duration | 1 Month |
| Introductory Offer | 7-day free trial |
| Price | $3.99 (ABD), ₺149 (Türkiye) |

**Ürün 2 — Yıllık:**
| Alan | Değer |
|---|---|
| Reference Name | SubSense Pro Yearly |
| Product ID | `com.subsense.pro.yearly` |
| Duration | 1 Year |
| Introductory Offer | 7-day free trial |
| Price | $29.99 (ABD), ₺899 (Türkiye) |

### 6.3 StoreKit Configuration Dosyası (Simulator Test)

Simulator'da gerçek satın alma yapılamaz. Test için:

1. Xcode → **File → New → File → StoreKit Configuration File**
2. Dosya adı: `Products.storekit`
3. `+` → Add Product → Auto-Renewable Subscription
4. Ürün ID: `com.subsense.pro.monthly`, fiyat: $3.99
5. Aynısını yıllıkla tekrarla
6. Scheme'i düzenle: **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → Products.storekit**

---

## 7. Widget App Group

Widget, ana uygulama ile veri paylaşmak için App Group kullanır.

### 7.1 Xcode'da App Group Ekle

1. **TARGETS → SubSense → Signing & Capabilities → + Capability**
2. **App Groups** ekle
3. `+` → `group.com.subsense.app`
4. Aynı işlemi **SubSenseWidgets** target'ı için yap, aynı group ID'yi seç

### 7.2 Ana Uygulamada Widget Veri Yazımı

`SubscriptionRepository.swift` içine aşağıdaki metodu ekle (widget'ın veri okuması için):

```swift
func updateWidgetData() {
    let defaults = UserDefaults(suiteName: "group.com.subsense.app")
    defaults?.set(NSDecimalNumber(decimal: monthlyTotal).doubleValue, forKey: "widget_monthly_total")
    defaults?.set(subscriptions.first?.currency ?? "USD", forKey: "widget_currency")
    if let next = subscriptions.filter({ $0.status == .active }).sorted(by: { $0.nextDate < $1.nextDate }).first {
        defaults?.set(next.name, forKey: "widget_next_name")
        defaults?.set(next.daysUntilRenewal, forKey: "widget_next_days")
        defaults?.set(next.effectiveBrandColor, forKey: "widget_next_color")
    }
    WidgetCenter.shared.reloadAllTimelines()
}
```

Bu metodu `add()`, `update()`, `delete()` işlemlerinin sonunda çağır.

---

## 8. Sign in with Apple

### 8.1 Apple Developer'da Service ID Oluştur

1. [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers → +** → **Services IDs** → Continue
3. Description: `SubSense SIWA`
4. Identifier: `com.subsense.app.siwa`
5. **Sign In with Apple** → Configure:
   - Primary App ID: `com.subsense.app`
   - Web Domain: `subsense.app`
   - Return URLs: `https://jnnzbmkefhcvrlkgrxgv.supabase.co/auth/v1/callback`
6. Continue → Register

### 8.2 Private Key Oluştur

1. **Keys → +** → İsim: `SubSense SIWA Key`
2. **Sign in with Apple** ✓ → Configure → Primary App ID: `com.subsense.app`
3. Continue → Register → **Download** (`.p8` dosyası — yalnızca bir kez indirilir, sakla!)
4. Key ID'yi not al (ör. `ABCD123456`)

### 8.3 Supabase'e Apple Provider Ekle

1. Supabase Dashboard → **Authentication → Providers → Apple**
2. `Services ID`: `com.subsense.app.siwa`
3. `Secret Key`: `.p8` dosyasının içeriği (başlık ve son satır dahil tümünü yapıştır)
4. `Team ID`: Apple Developer hesabı Team ID'n (Membership sayfasında yazar)
5. `Key ID`: Az önce not aldığın Key ID

### 8.4 Xcode Capability Ekle

1. **TARGETS → SubSense → Signing & Capabilities → + Capability**
2. **Sign in with Apple** ekle

---

## 9. Push Bildirimleri (APNs)

Uygulama yerel bildirimler kullanıyor (APNs gerektirmiyor), ancak ileride uzak bildirimler için hazırlık:

### 9.1 Xcode Capability

1. **TARGETS → SubSense → Signing & Capabilities → + Capability**
2. **Push Notifications** ekle
3. **Background Modes** → `Remote notifications` ✓

### 9.2 APNs Key (İleride Supabase'e Gerekecek)

1. developer.apple.com → **Keys → +**
2. İsim: `SubSense APNs Key`
3. **Apple Push Notifications service (APNs)** ✓
4. Register → Download `.p8`
5. Supabase Dashboard → **Project Settings → Auth → Push Notifications**'a yükle

---

## 10. Supabase Edge Functions

Üç edge function deploy edilmesi gerekiyor. Önce Supabase CLI'yı yükle:

```bash
brew install supabase/tap/supabase
supabase login
```

### 10.1 Proje Dizini Oluştur

```bash
cd /Volumes/ProjectVault/SubSense-IOS
mkdir -p supabase/functions/ai-insights
mkdir -p supabase/functions/ai-chat
mkdir -p supabase/functions/exchange-rates
mkdir -p supabase/functions/storekit-notifications
```

### 10.2 `ai-insights` Function

`supabase/functions/ai-insights/index.ts` dosyası oluştur:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

serve(async (req) => {
  const { subscriptions, baseCurrency, language } = await req.json();
  const apiKey = Deno.env.get("GEMINI_API_KEY")!;

  const lang = language === "tr" ? "Türkçe" : "English";
  const prompt = `Analyze these subscriptions and return JSON insights. Language: ${lang}.
Subscriptions: ${JSON.stringify(subscriptions)}
Base currency: ${baseCurrency}

Return ONLY valid JSON: {"insights": [{"type": "redundancy"|"cycle_swap", "title": "...", "description": "...", "estimatedSavings": number|null, "relatedServices": ["..."]}]}
Max 3 insights. Focus on real savings opportunities.`;

  const resp = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: "application/json" }
    }),
  });

  const data = await resp.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '{"insights":[]}';

  return new Response(text, {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
  });
});
```

### 10.3 `ai-chat` Function

`supabase/functions/ai-chat/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

serve(async (req) => {
  const { message, subscriptions, baseCurrency, language } = await req.json();
  const apiKey = Deno.env.get("GEMINI_API_KEY")!;

  const lang = language === "tr" ? "Türkçe" : "English";
  const context = `You are SubSense AI assistant. User's subscriptions: ${JSON.stringify(subscriptions)}. Base currency: ${baseCurrency}. Reply in ${lang}. Be concise, helpful, and specific about their subscriptions.`;

  const resp = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        { role: "user", parts: [{ text: context }] },
        { role: "model", parts: [{ text: "Understood. I'll help analyze your subscriptions." }] },
        { role: "user", parts: [{ text: message }] }
      ]
    }),
  });

  const data = await resp.json();
  const reply = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "Sorry, I couldn't process that.";

  return new Response(JSON.stringify(reply), {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
  });
});
```

### 10.4 `exchange-rates` Function

`supabase/functions/exchange-rates/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Fallback rates (USD base)
const FALLBACK_RATES: Record<string, number> = {
  USD: 1, EUR: 0.92, GBP: 0.79, TRY: 32.5, JPY: 149.5,
  CAD: 1.36, AUD: 1.53, CHF: 0.89, SEK: 10.5, NOK: 10.8,
  DKK: 6.89, PLN: 4.02, CZK: 23.1, HUF: 357, RON: 4.57,
  BGN: 1.8, HRK: 6.93, RUB: 90.5, UAH: 38.0, INR: 83.1,
  BRL: 4.97, MXN: 17.2, ARS: 850, CLP: 890, COP: 3950,
  KRW: 1325, CNY: 7.24, HKD: 7.82, SGD: 1.34, NZD: 1.63,
};

serve(async () => {
  return new Response(
    JSON.stringify({ base: "USD", rates: FALLBACK_RATES, updated_at: new Date().toISOString() }),
    { headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
  );
});
```

### 10.5 Functions Deploy Et

```bash
# Önce Gemini API key'i secret olarak ekle
supabase secrets set GEMINI_API_KEY=BURAYA_GEMINI_ANAHTARINI_YAZ --project-ref jnnzbmkefhcvrlkgrxgv

# Deploy
supabase functions deploy ai-insights --project-ref jnnzbmkefhcvrlkgrxgv
supabase functions deploy ai-chat --project-ref jnnzbmkefhcvrlkgrxgv
supabase functions deploy exchange-rates --project-ref jnnzbmkefhcvrlkgrxgv
```

---

## 11. Deep Link (Universal Links)

Email doğrulama ve şifre sıfırlama için gerekli.

### 11.1 apple-app-site-association Dosyası

Web sunucuna (veya Supabase Storage'a `public` bucket'a) şu dosyayı yükle:
URL: `https://subsense.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.subsense.app",
        "paths": ["/verify*", "/reset*"]
      }
    ]
  }
}
```

> `TEAM_ID` yerine Apple Developer hesabı Team ID'ni yaz.

### 11.2 Xcode Associated Domains

1. **TARGETS → SubSense → Signing & Capabilities → + Capability**
2. **Associated Domains** → `+`
3. Değer: `applinks:subsense.app`

> Gerçek domainин yoksa şimdilik bu adımı atla; email doğrulama çalışmayacak ama geri kalan her şey çalışır.

---

## 12. İlk Derleme ve Test

### 12.1 Simulator'da Derle

```
Cmd + R
```

Sorunsuz derlenmesi beklenen şeyler:
- Onboarding ekranı (3 sayfa, animasyonlu)
- Auth ekranı (email/şifre + Apple butonu)
- Dashboard (boş state)

### 12.2 Sık Karşılaşılan Hatalar

| Hata | Çözüm |
|---|---|
| `Missing Config.plist` | `SubSense/App/Config/Config.plist` dosyasının var olduğunu kontrol et |
| `No such module 'Supabase'` | File → Packages → Resolve Package Versions |
| `Signing requires a development team` | §5.2'yi uygula |
| `Bundle ID already taken` | §5.3'teki gibi bundle ID'yi değiştir |
| `WidgetKit: App group not found` | §7.1'i uygula |

### 12.3 Temel Akışı Test Et

Simulator'da sırasıyla:

- [ ] Onboarding 3 sayfayı geç
- [ ] Hesap oluştur (email + şifre)
- [ ] Dashboard açıldı mı?
- [ ] `+` butonuna bas → abonelik ekle (ör. Netflix $15.99)
- [ ] Dashboard'da aylık toplam güncellendi mi?
- [ ] Subscription List'te göründü mü?
- [ ] Swipe-to-delete çalıştı mı?
- [ ] Analytics sekmesi açıldı mı?
- [ ] Settings'den çıkış yap → tekrar giriş yap

---

## 13. App Store'a Gönderme

### 13.1 App Store Connect Bilgilerini Doldur

1. Uygulamanın App Store sayfasına git
2. **App Information**:
   - Kategory: Finance
   - Secondary Category: Productivity
3. **Pricing and Availability**: Ücretsiz (IAP ile monetize)
4. **Privacy Policy URL**: `https://subsense.app/privacy`

### 13.2 Lokalizasyon

App Store'da hem EN hem TR açıklama yaz:

**EN — App Description (ilk 3 satır en önemli):**
```
Track every subscription. Get AI insights. Never get surprise-billed again.

SubSense gives you a beautiful, single view of all your recurring charges — Netflix, Spotify, ChatGPT, iCloud, gym memberships — in your own currency. Our AI detects when you're overpaying and tells you exactly how to save.

• Real-time multi-currency (20+ currencies)
• AI insights that find redundant services
• Renewal reminders 3 days before any charge
• Offline-first, private by design
```

**TR — App Description:**
```
Tüm aboneliklerinizi takip edin. AI önerileri alın. Sürpriz ücretlere son.

SubSense, Netflix, Spotify, ChatGPT, iCloud, spor salonu üyeliği gibi tüm yinelenen ödemelerinizi kendi para biriminizde tek, güzel bir ekranda gösterir. AI'mız fazla ödediğiniz servisleri tespit eder ve tam olarak nasıl tasarruf edeceğinizi söyler.

• Gerçek zamanlı çoklu para birimi (20+)
• Gereksiz servisleri bulan AI önerileri
• Her ödemeden 3 gün önce yenileme bildirimleri
• Çevrimdışı öncelikli, gizlilik odaklı tasarım
```

### 13.3 Screenshot Oluştur

Gerekli cihaz boyutları:
- iPhone 6.7" (iPhone 15 Pro Max Simulator)
- iPhone 6.1" (iPhone 15 Simulator)

Her boyut için en az 3 screenshot önerilen ekranlar:
1. Dashboard (birkaç abonelik eklenmiş)
2. Add Subscription ekranı
3. Analytics ekranı

Xcode'da screenshot al: `Cmd + Shift + 4` → Simulator penceresini seç

### 13.4 Archive ve Upload

1. Xcode → **Product → Destination → Any iOS Device (arm64)**
2. **Product → Archive**
3. Archive tamamlanınca Organizer açılır → **Distribute App**
4. **App Store Connect → Upload**
5. App Store Connect'te build göründükten sonra (10-30 dk) Submit for Review

### 13.5 Review Öncesi Kontrol Listesi

**Apple zorunluluklarını kontrol et:**
- [ ] Sign in with Apple butonu görünür (`AuthFlowView`)
- [ ] Hesap silme özelliği çalışıyor (`SettingsView → Delete Account`)
- [ ] Privacy Policy URL geçerli bir sayfaya gidiyor
- [ ] App Store'da yalnızca Apple IAP ile ödeme alınıyor (PaywallView)
- [ ] Restore Purchases butonu var ve çalışıyor
- [ ] Uygulamada başka ödeme yöntemi referansı yok

**Teknik kontroller:**
- [ ] Gerçek cihazda test edildi (Simulator yetmez)
- [ ] Çevrimdışı durum test edildi (uçak modu)
- [ ] Dark mode her ekranda test edildi
- [ ] Büyük metin boyutlarında (Accessibility → Larger Text) düzen bozulmuyor

---

## Özet Tablo

| Adım | Süre (tahmini) | Bağımlılık |
|---|---|---|
| Supabase Email/Apple Auth | 15 dk | Apple Developer hesabı |
| Gemini API Key | 5 dk | Google hesabı |
| Config.plist güncelle | 2 dk | Gemini key |
| Xcode team ayarla | 5 dk | Apple Developer hesabı |
| App Store Connect — app oluştur | 10 dk | Apple Developer hesabı |
| StoreKit ürünleri | 20 dk | App Store Connect app |
| App Group (widget) | 5 dk | Xcode açık |
| Sign in with Apple | 20 dk | Apple Developer hesabı |
| Edge functions deploy | 15 dk | Supabase CLI, Gemini key |
| İlk derleme + test | 30 dk | Tüm yukarıdakiler |
| App Store gönderme | 30 dk | Archive + screenshots |

**Toplam: ~2.5-3 saat**

---

*SubSense iOS — Blueprint v1.0*
