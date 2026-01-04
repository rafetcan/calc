# Changelog

Tüm önemli değişiklikler bu dosyada belgelenecektir.

Format [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) standardına uygundur,
ve bu proje [Semantic Versioning](https://semver.org/lang/tr/) kullanmaktadır.

## [Unreleased]

### Changed
- Proje yapısı Clean Architecture prensiplerine göre yeniden düzenlendi
- MVVM pattern implementasyonu iyileştirildi
- Dependency Injection yapısı GetIt ile güncellendi
- Localization dosyaları JSON formatına geçirildi

### Removed
- Eski model dosyaları (`calculator_model.dart`, `feedback_model.dart`)
- Eski provider dosyaları (`theme_provider.dart`)
- Eski service dosyaları (`ad_service.dart`, `feedback_service.dart`)
- Eski view dosyaları (`calculator_view.dart`, `feedback_dialog.dart`)
- Eski viewmodel dosyaları (`calculator_viewmodel.dart`)
- Eski localization dosyaları (`app_en.arb`, `app_tr.arb`)



## [1.1.0] - 2025-12-04
- [Yeni] Tema
- [Yeni] Android için hızlı erişim (App Shortcuts) eklendi. (Kullanıcı isteği)
- [Yeni] İcon
- [Yeni] Kopyala / Yapıştır özelliği (Kullanıcı isteği)

- [Düzeltme] Rota işlemleri iyileiştirildi.



## [1.0.2] - 2025-10-20
- [New] calculator_prd.md ile Yol Haritası
- [New] TestUnit eklendi.

- [Edit] .cursorrules ile uygulamaya uygun kurallar
- [Edit]  README.md ile uygulama içeriği, yapısı, yapılanları eklendi.
- [Edit] Performans iyileştirmesi yapıldı.
- [Edit] Geçmiş sayfası düzenlendi.
- [Edit] Arkaplan ve button renkleri düzenlendi.

- [Fix] Çıkarma işlemi düzeltildi.

## [1.0.1] - 2025-02-25

### Added
- **Mimari Yapı**
  - Clean Architecture prensipleri ile proje yapısı oluşturuldu
  - MVVM (Model-View-ViewModel) pattern implementasyonu
  - Dependency Injection (GetIt) entegrasyonu
  - Repository pattern ile veri yönetimi
  - Core modülü (DI, services, theme)
  - Features modülü (calculator, feedback)

- **Hesap Makinesi Özellikleri**
  - Temel matematiksel işlemler (toplama, çıkarma, çarpma, bölme)
  - İşlem önceliği desteği
  - Hata kontrolü ve validasyon
  - İşlem geçmişi görüntüleme ve yönetimi
  - Geçmiş işlemlerden tekrar kullanım özelliği

- **Kullanıcı Arayüzü**
  - Responsive tasarım (minimum 320px ekran desteği)
  - Portrait ve landscape mod desteği
  - Modern ve kullanıcı dostu UI tasarımı
  - Accessibility standartlarına uyumlu elementler

- **Tema Sistemi**
  - Dark/Light mode desteği
  - Sistem teması entegrasyonu
  - Tema tercihlerinin kalıcı saklanması
  - Tema değiştirme özelliği

- **Çoklu Dil Desteği**
  - Türkçe ve İngilizce dil desteği
  - Easy Localization entegrasyonu
  - Cihaz diline göre otomatik dil seçimi
  - Manuel dil değiştirme özelliği
  - Tüm string'lerin localize edilmesi

- **Firebase Entegrasyonu**
  - Firebase Core entegrasyonu
  - Firebase Crashlytics implementasyonu
  - Firebase Analytics entegrasyonu
  - Hata yakalama ve raporlama sistemi
  - Firebase güvenlik kuralları

- **Geri Bildirim Sistemi**
  - Kullanıcı geri bildirimi formu
  - Feedback servisi implementasyonu
  - Firestore entegrasyonu

- **Veri Yönetimi**
  - SharedPreferences ile local storage
  - Hive entegrasyonu hazırlığı
  - İşlem geçmişi persistence
  - Kullanıcı tercihlerinin saklanması

- **Test Altyapısı**
  - Unit test framework'ü
  - Widget test framework'ü
  - Mockito entegrasyonu
  - Test coverage raporlama

- **CI/CD Pipeline**
  - GitHub Actions workflow'ları
  - Otomatik test çalıştırma
  - Kod analizi
  - Otomatik build ve release
  - Test coverage raporlama

- **Dokümantasyon**
  - README.md dosyası
  - PRD (Product Requirements Document)
  - Mockup tasarım dokümantasyonu
  - Proje kurulum rehberi

### Changed
- Android build konfigürasyonu güncellendi
- iOS konfigürasyonu güncellendi
- Firebase options yapılandırması eklendi

### Technical Details
- **Flutter SDK**: >=3.0.0 <4.0.0
- **State Management**: Provider ^6.1.1
- **Dependency Injection**: GetIt ^7.6.7
- **Local Storage**: SharedPreferences ^2.2.2, Hive ^2.2.3
- **Localization**: Easy Localization ^3.0.3
- **Firebase**: Core ^2.24.2, Crashlytics ^3.4.9, Analytics ^10.8.0, Firestore ^4.17.5
- **Testing**: Mockito ^5.4.4, Build Runner ^2.4.8

---

## Versiyonlama Notları

- **Major** (X.0.0): Geriye dönük uyumsuz API değişiklikleri
- **Minor** (0.X.0): Geriye dönük uyumlu yeni özellikler
- **Patch** (0.0.X): Geriye dönük uyumlu hata düzeltmeleri

[Unreleased]: https://github.com/username/calculator-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/calculator-app/releases/tag/v1.0.0

