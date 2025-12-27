# Changelogs

## [1.0.0] - Unreleased

### Added
- İlk stabil sürüm
- Event tracking desteği
- SecureStorage entegrasyonu
  - Session ID ve Anonymous ID güvenli saklama
  - Base64 obfuscation
- Input validation
  - Event parametreleri validasyonu
  - Performance event parametreleri validasyonu
- Debug logging desteği
  - Runtime debug logging kontrolü
  - OSLog entegrasyonu
- Automatic Retry
  - Ağ hatalarında otomatik yeniden deneme
  - Exponential backoff
- Environment support
  - Production ve Staging ortamları
  - Environment bazlı URL yapılandırması
- Swift Package Manager desteği
- GitHub Actions CI/CD pipeline
  - PR workflow (test + coverage + lint)
  - Production release workflow
  - Staging beta release workflow
- Unit testler

### Security
- SecureStorage ile hassas veri saklama
- Input validation
- Thread-safe singleton yapı

### Changed
- **SecureStorage güvenlik iyileştirmeleri**
  - UserDefaults yerine iOS Keychain kullanımına geçiş
  - CryptoKit ile AES-GCM encryption desteği
  - Hassas verilerin (Session ID, Anonymous ID) şifrelenmiş saklanması
  - Keychain erişim seviyesi: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  - UserDefaults'tan Keychain'e otomatik veri migration (backward compatibility)
- **API Client güvenlik iyileştirmeleri**
  - URL logging'de query parametrelerinin maskelenmesi
  - Debug loglarında hassas veri sızıntısının önlenmesi
  - Sadece scheme, host ve path bilgisinin loglanması
