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
