# Mimeda Bidding iOS SDK

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS%2013.0%2B-blue)](https://github.com/Mimeda/bidding-mobile-ios-sdk-release#gereksinimler)
[![SDK Source](https://img.shields.io/badge/source-github-blueviolet)](https://github.com/Mimeda/bidding-mobile-ios-sdk-release)

Mimeda iOS SDK, Mimeda bidding platformu için geliştirilmiş, event tracking ve performance monitoring özellikleri sunan bir iOS kütüphanesidir.

## İçindekiler

- [Özellikler](#özellikler)
- [Kurulum](#kurulum)
  - [Swift Package Manager](#swift-package-manager)
  - [XCFramework](#xcframework)
  - [Kullanılan Framework'ler](#kullanılan-frameworkler)
- [Hızlı Başlangıç](#hızlı-başlangıç)
- [API Referansı](#api-referansı)
- [Debug Logging](#debug-logging)
- [Gereksinimler](#gereksinimler)
- [Güvenlik](#güvenlik)
- [Sorun Giderme](#sorun-giderme)
- [Gitflow ve CI/CD](#gitflow-ve-cicd)
- [Destek](#destek)
- [Sürüm Geçmişi](#-sürüm-geçmişi)

## Özellikler

- **Event Tracking**: Kullanıcı etkileşimlerini takip edin
- **Performance Monitoring**: Reklam performans metriklerini izleyin
- **Güvenli Data Storage**: iOS Keychain ve CryptoKit ile hassas verilerin güvenli saklanması
- **Input Sanitization**: Otomatik veri temizleme (XSS, HTML tag, SQL injection koruması)
- **Automatic Retry**: Network hatalarında otomatik yeniden deneme
- **Debug Logging**: Geliştirme sırasında detaylı log desteği (OSLog)
- **Environment Support**: Production ve Staging ortamları desteği

## Kurulum

### Swift Package Manager

Xcode'da projenize SDK'yı eklemek için:

1. **File > Add Packages...** menüsüne gidin
2. Aşağıdaki URL'yi girin:

```
https://github.com/Mimeda/bidding-mobile-ios-sdk-release.git
```

3. **Dependency Rule** olarak istediğiniz versiyonu seçin:(latest versiyon için linki ziyaret edebilirsiniz.)
   - **Up to Next Major Version**: `1.0.0`
   - **Exact Version**: `1.0.0`


### Kullanılan Framework'ler

SDK, aşağıdaki native iOS framework'lerini kullanır (harici bağımlılık yoktur):

- **Foundation**
  - Temel Swift ve Objective-C API'leri için kullanılır
- **Security**
  - iOS Keychain Services ile hassas verilerin güvenli saklanması için kullanılır
- **CryptoKit**
  - AES-GCM encryption ile verilerin şifrelenmesi için kullanılır
- **OSLog**
  - Debug logging ve sistem log entegrasyonu için kullanılır

## Hızlı Başlangıç

### 1. SDK'yı Import Edin

```swift
import bidding_mobile_ios_sdk
```

### 2. SDK'yı Başlatın

> **Not:** Session ID ve Anonymous ID, SDK tarafından otomatik olarak yönetilir. SDK, session'ları otomatik olarak oluşturur, saklar ve 30 dakika sonra yeniler. Anonymous ID de SDK tarafından otomatik olarak oluşturulur ve yönetilir. Bu değerler için herhangi bir işlem yapmanıza gerek yoktur.

#### SwiftUI Uygulamalarında

```swift
import SwiftUI
import bidding_mobile_ios_sdk

@main
struct MyApp: App {
    init() {
        // SDK'yı başlat
        MimedaSDK.shared.initialize(
            apiKey: "YOUR_API_KEY"
        )
        
        // Geliştirme sırasında debug loglarını açabilirsiniz
        MimedaSDK.shared.setDebugLogging(true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### UIKit Uygulamalarında (AppDelegate)

```swift
import UIKit
import bidding_mobile_ios_sdk

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // SDK'yı başlat
        MimedaSDK.shared.initialize(
            apiKey: "YOUR_API_KEY",
            environment: .production // veya .staging
        )
        
        // Geliştirme sırasında debug loglarını açabilirsiniz
        MimedaSDK.shared.setDebugLogging(true)
        
        return true
    }
}
```

### 3. Event Tracking

Kullanıcı etkileşimlerini takip edin. Tüm parametreler opsiyoneldir:

```swift
import bidding_mobile_ios_sdk

// EventParams oluşturma - tüm parametreler opsiyoneldir
let params = EventParams(
    app: "ios-app",                        // Uygulama adı (opsiyonel)
    userId: "user123",                     // Kullanıcı ID (opsiyonel)
    lineItemIds: "milk123",                // Line item ID’si süt ürünü (örnek)
    productList: "SUT001:2:42.99",         // Süt ürünü - SKU:adet:fiyat örn: SUT001:2:42.99
    categoryId: "dairy",                   // Kategori ID: süt ürünleri (opsiyonel)
    keyword: "süt",                        // Arama kelimesi: süt (opsiyonel)
    loyaltyCard: "LC123456",               // Sadakat kartı (opsiyonel)
    transactionId: "txn456",               // İşlem ID (opsiyonel)
    totalRowCount: 15                      // Toplam satır sayısı (opsiyonel)
)

// Event gönderme
MimedaSDK.shared.trackEvent(
    eventName: .home,        // .home, .listing, .search, .pdp, .cart, .purchase
    eventParameter: .view,   // .view, .addToCart, .addToFavorites, .success
    params: params
)
```

#### Event Örnekleri

```swift
// Home / View - Ana sayfa görüntüleme
MimedaSDK.shared.trackEvent(
    eventName: .home,
    eventParameter: .view,
    params: EventParams()
)

// Home / AddtoCart - Ana sayfadan sepete ekleme
MimedaSDK.shared.trackEvent(
    eventName: .home,
    eventParameter: .addToCart,
    params: EventParams(
        lineItemIds: "item123",
        productList: "08060192:1:10.50"
    )
)

// Listing / View - Ürün listesi görüntüleme
MimedaSDK.shared.trackEvent(
    eventName: .listing,
    eventParameter: .view,
    params: EventParams(
        categoryId: "electronics",
        totalRowCount: 50
    )
)

// Search / View - Arama sonuçları görüntüleme
MimedaSDK.shared.trackEvent(
    eventName: .search,
    eventParameter: .view,
    params: EventParams(
        keyword: "telefon",
        categoryId: "electronics"
    )
)

// PDP / View - Ürün detay sayfası görüntüleme
MimedaSDK.shared.trackEvent(
    eventName: .pdp,
    eventParameter: .view,
    params: EventParams(
        lineItemIds: "item123",
        productList: "08060192:1:10.50"
    )
)

// Cart / View - Sepet sayfası görüntüleme
MimedaSDK.shared.trackEvent(
    eventName: .cart,
    eventParameter: .view,
    params: EventParams(
        lineItemIds: "item123,item456",
        productList: "08060192:1:10.50,08060193:2:25.00"
    )
)

// Purchase / Success - Satın alma işlemi başarılı
MimedaSDK.shared.trackEvent(
    eventName: .purchase,
    eventParameter: .success,
    params: EventParams(
        transactionId: "txn789",
        lineItemIds: "item123,item456",
        productList: "08060192:1:10.50,08060193:2:25.00"
    )
)
```

### 4. Performance Event Tracking

Reklam performans metriklerini takip edin. Tüm parametreler opsiyoneldir:

```swift
import bidding_mobile_ios_sdk

// PerformanceEventParams oluşturma - tüm parametreler opsiyoneldir
let params = PerformanceEventParams(
    app: "ios-app",              // Uygulama adı (opsiyonel)
    lineItemId: "line123",       // Line item ID (opsiyonel)
    creativeId: "creative456",   // Creative ID (opsiyonel)
    adUnit: "banner_top",        // Ad unit (opsiyonel)
    productSku: "SKU789",        // Ürün SKU (opsiyonel)
    payload: "custom_data",      // Özel veri (opsiyonel)
    keyword: "electronics",      // Arama kelimesi (opsiyonel)
    userId: "user123"            // Kullanıcı ID (opsiyonel)
)

// Impression (Görüntülenme) gönderme
MimedaSDK.shared.trackPerformanceImpression(params: params)

// Click (Tıklama) gönderme
MimedaSDK.shared.trackPerformanceClick(params: params)
```

#### Performance Event Örnekleri

```swift
// Impression (Görüntülenme)
MimedaSDK.shared.trackPerformanceImpression(
    params: PerformanceEventParams(
        lineItemId: "line123",
        creativeId: "creative456",
        adUnit: "banner_top",
        productSku: "SKU789"
    )
)

// Click (Tıklama)
MimedaSDK.shared.trackPerformanceClick(
    params: PerformanceEventParams(
        lineItemId: "line123",
        creativeId: "creative456",
        adUnit: "banner_top",
        productSku: "SKU789",
        payload: "custom_data"
    )
)
```

## API Referansı

### MimedaSDK

Ana SDK sınıfı. Tüm işlemler `MimedaSDK.shared` singleton üzerinden yapılır. SDK yalnızca bir kez initialize edilmelidir. Tekrar initialize edilirse çağrı yok sayılır.

#### `initialize()`

SDK'yı başlatır.

```swift
func initialize(
    apiKey: String,
    environment: SDKEnvironment = .production,
    errorCallback: MimedaSDKErrorCallback? = nil
)
```

**Parametreler:**
- `apiKey`: Mimeda API anahtarı
- `environment`: `.production` veya `.staging`
- `errorCallback`: Hata durumlarında çağrılacak callback (opsiyonel)

#### `trackEvent()`

Event tracking için kullanılır.

```swift
func trackEvent(
    eventName: EventName,
    eventParameter: EventParameter,
    params: EventParams = EventParams()
)
```

#### `trackPerformanceImpression()` / `trackPerformanceClick()`

Performance event tracking için kullanılır.

```swift
func trackPerformanceImpression(params: PerformanceEventParams)
func trackPerformanceClick(params: PerformanceEventParams)
```

#### `setDebugLogging()`

Debug loglarını açıp kapatır.

```swift
func setDebugLogging(_ enabled: Bool)
```

#### `isInitialized()`

SDK'nın başlatılıp başlatılmadığını kontrol eder.

```swift
func isInitialized() -> Bool
```

#### `shutdown()`

SDK'yı kapatır ve kaynakları temizler.

```swift
func shutdown()
```

### EventName

Kullanılabilir event isimleri:

- `home` - Ana sayfa
- `listing` - Ürün listesi
- `search` - Arama
- `pdp` - Ürün detay sayfası
- `cart` - Sepet
- `purchase` - Satın alma

### EventParameter

Kullanılabilir event parametreleri:

- `view` - Görüntüleme
- `addToCart` - Sepete ekleme
- `addToFavorites` - Favorilere ekleme
- `success` - Başarılı işlem

### EventParams

Event parametreleri için struct:

```swift
struct EventParams {
    let app: String?
    let userId: String?
    let lineItemIds: String?
    let productList: String?
    let categoryId: String?
    let keyword: String?
    let loyaltyCard: String?
    let transactionId: String?
    let totalRowCount: Int?
    
    init(
        app: String? = nil,
        userId: String? = nil,
        lineItemIds: String? = nil,
        productList: String? = nil,
        categoryId: String? = nil,
        keyword: String? = nil,
        loyaltyCard: String? = nil,
        transactionId: String? = nil,
        totalRowCount: Int? = nil
    )
}
```

### PerformanceEventParams

Performance event parametreleri için struct. Tüm alanlar opsiyoneldir, validasyon backend tarafında yapılmaktadır:

```swift
struct PerformanceEventParams {
    let app: String?          // Opsiyonel
    let lineItemId: String?   // Opsiyonel
    let creativeId: String?   // Opsiyonel
    let adUnit: String?       // Opsiyonel
    let productSku: String?   // Opsiyonel
    let payload: String?      // Opsiyonel
    let keyword: String?      // Opsiyonel
    let userId: String?       // Opsiyonel
    
    init(
        app: String? = nil,
        lineItemId: String? = nil,
        creativeId: String? = nil,
        adUnit: String? = nil,
        productSku: String? = nil,
        payload: String? = nil,
        keyword: String? = nil,
        userId: String? = nil
    )
}
```

### MimedaSDKErrorCallback

Hata durumlarını yakalamak için protocol:

```swift
protocol MimedaSDKErrorCallback: AnyObject {
    func onEventTrackingFailed(
        eventName: EventName,
        eventParameter: EventParameter,
        error: Error
    )
    
    func onPerformanceEventTrackingFailed(
        eventType: PerformanceEventType,
        error: Error
    )
    
    func onValidationFailed(
        eventName: EventName?,
        errors: [String]
    )
}
```

**Kullanım örneği:**

```swift
class MyErrorHandler: MimedaSDKErrorCallback {
    func onEventTrackingFailed(
        eventName: EventName,
        eventParameter: EventParameter,
        error: Error
    ) {
        // Event tracking hatası (network hatası vb.)
        print("Event tracking failed: \(eventName)/\(eventParameter) - \(error)")
    }
    
    func onPerformanceEventTrackingFailed(
        eventType: PerformanceEventType,
        error: Error
    ) {
        // Performance event tracking hatası (network hatası vb.)
        print("Performance event failed: \(eventType) - \(error)")
    }
    
    func onValidationFailed(
        eventName: EventName?,
        errors: [String]
    ) {
        // Validasyon hatası
        print("Validation failed: \(errors.joined(separator: ", "))")
    }
}

// Kullanım
let errorHandler = MyErrorHandler()

MimedaSDK.shared.initialize(
    apiKey: "YOUR_API_KEY",
    environment: .production,
    errorCallback: errorHandler
)
```

## Debug Logging

Geliştirme sırasında debug loglarını açmak için:

```swift
MimedaSDK.shared.setDebugLogging(true)
```

**Önemli Notlar:**
- Debug logging, release build'lerde de teknik olarak çalışabilir, ancak production ortamlarında kesinlikle açık bırakılmamalıdır
- Production build'lerde varsayılan olarak kapalıdır
- Loglar OSLog entegrasyonu ile Console.app'te veya Xcode Console'da görüntülenir

## Gereksinimler

- **Minimum iOS:** iOS 13.0+
- **Swift:** 5.7+
- **Xcode:** 14.0+

## Güvenlik

SDK, aşağıdaki güvenlik özelliklerini içerir:

- **iOS Keychain**: Hassas veriler iOS Keychain'de güvenli bir şekilde saklanır
- **CryptoKit AES-GCM**: Veriler AES-GCM encryption ile şifrelenir
- **Keychain Accessibility**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` erişim seviyesi
- **Input Sanitization**: Tüm kullanıcı girdileri otomatik olarak temizlenir (XSS, HTML tag, SQL injection koruması)
- **Secure Storage**: Session ID ve Anonymous ID güvenli bir şekilde saklanır

## Thread Safety

- `MimedaSDK.shared` bir Swift singleton olarak tasarlanmıştır
- `NSLock` kullanılarak thread-safe erişim sağlanır
- Event gönderimi için `DispatchQueue` ile asenkron işlem yapılır
- Tüm network işlemleri background thread'de gerçekleştirilir

## Performance Considerations

- Event ve performance çağrıları **asenkron** olarak çalıştırılır; bu sayede ana thread (UI thread) bloklanmaz
- Her event, kendi HTTP isteği olarak gönderilir; şu anda batching yoktur
- **Retry mekanizması** uygulanır:
  - Network hatalarında maksimum retry sayısına kadar yeniden deneme yapılır
  - Yeniden denemeler arasında exponential backoff benzeri artan gecikme süresi kullanılır
- Tüm ağ istekleri URLSession üzerinden, arka planda çalışan thread'lerde gerçekleştirilir

## Sorun Giderme

### SDK başlatılmadı hatası

```swift
if !MimedaSDK.shared.isInitialized() {
    MimedaSDK.shared.initialize(apiKey: apiKey)
}
```

### Event tracking çalışmıyor

1. SDK'nın başlatıldığından emin olun
2. API key'in doğru olduğunu kontrol edin
3. Network bağlantısının olduğundan emin olun
4. Debug logging'i açıp logları kontrol edin

### Loglar görünmüyor

```swift
// Debug logging'i açın
MimedaSDK.shared.setDebugLogging(true)

// Console.app veya Xcode Console'da "MimedaSDK" subsystem'ini filtreleyin
```

## Gitflow ve CI/CD

Bu proje, GitHub Actions ile otomatik CI/CD pipeline'ı kullanır. Aşağıda branch stratejisi, PR süreci ve deployment akışı açıklanmaktadır.

### Branch Stratejisi

#### Staging Branch
- **Branch:** `staging`
- **Versiyon Formatı:** `1.0.0-beta.X`
  - **X:** GitHub Actions run numarası (`github.run_number`) - her CI/CD çalıştırmasında otomatik artar
  - **Örnek:** `1.0.0-beta.36` (36. CI/CD run'ı)
- **Deployment:** Beta sürümü olarak release

#### Production Branch
- **Branch:** `master` veya `main`
- **Versiyon:** `SDKConfig.swift` dosyasındaki `sdkVersion` değerinden okunur
- **Deployment:** Production release (manual approval gerekli)

### PR Workflow

1. **PR Açma:**
   - PR'lar `main`, `master` veya `staging` branch'lerine açılmalıdır
   - PR açıldığında otomatik olarak şu job'lar çalışır:
     - `build-and-test`: Proje build edilir, unit testler çalıştırılır, coverage raporu oluşturulur
     - `lint`: SwiftLint ile kod kalitesi kontrolü yapılır

2. **PR Merge:**
   - PR merge edildiğinde (push event) `deploy` job'ı çalışır
   - Branch'e göre otomatik deployment yapılır

### Workflow Özeti

```
┌─────────────┐
│   PR Açma   │
└──────┬──────┘
       │
       ├─→ Build & Test
       ├─→ SwiftLint Check
       │
       ▼
┌─────────────┐
│  PR Merge   │
└──────┬──────┘
       │
       ├─→ Staging Branch?
       │   └─→ Beta Release (Otomatik)
       │
       └─→ Master/Main Branch?
           └─→ Production Release (Otomatik)
```

## Destek

- **Website:** [https://mimeda.com.tr](https://mimeda.com.tr)
- **Issues:** GitHub Issues üzerinden sorun bildirebilirsiniz

## 📝 Sürüm Geçmişi

Detaylı değişiklik listesi için [CHANGELOG.md](CHANGELOG.md) dosyasına bakın.