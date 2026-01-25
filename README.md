# Calculator App

Modern, çok dilli ve kullanıcı dostu bir Flutter hesap makinesi uygulaması.

## Özellikler (Planlanan)

- 📱 Responsive tasarım
- 🌙 Dark/Light mode desteği
- 🌍 Çoklu dil desteği (TR/EN/ZH/ES/Hİ)
- 📊 İşlem geçmişi
- 🐛 Hata bildirimi sistemi
- 💾 Yerel veri depolama

## Teknolojiler & Paketler

- Flutter & Dart
- Provider (State Management)
- GetIt (Dependency Injection)
- Hive (Local Storage)
- Easy Localization
- Firebase Crashlytics
- Flutter Test
- GitHub Actions

## Kurulum

1. Flutter'ı yükleyin (https://flutter.dev/docs/get-started/install)

2. Repository'yi klonlayın
```bash
git clone https://github.com/username/calculator-app.git
```

3. Gerekli paketleri yükleyin
```bash
flutter pub get
```

4. Firebase yapılandırmasını ayarlayın
```bash
flutterfire configure
```

5. Test mock'larını oluşturun
```bash
flutter pub run build_runner build
```

6. Uygulamayı çalıştırın
```bash
flutter run
```

## CI/CD

Bu proje GitHub Actions ile otomatik CI/CD pipeline'ına sahiptir:

- Her push ve pull request'te:
  - Kod analizi yapılır
  - Unit ve widget testleri çalıştırılır
  - Test coverage raporu oluşturulur
  - Release APK build edilir

- Main branch'e push yapıldığında:
  - Otomatik release oluşturulur
  - APK GitHub Releases'a yüklenir

## Yapılanlar ✅

### Faz 1 - Temel Özellikler
- [x] Proje yapısının oluşturulması
  - [x] MVVM klasör yapısı oluşturuldu
  - [x] Temel model sınıfları oluşturuldu
  - [x] ViewModel yapısı kuruldu
  - [x] Provider entegrasyonu yapıldı
  - [x] Ana uygulama yapısı oluşturuldu
- [x] Temel hesap makinesi UI tasarımı
  - [x] Ana ekran yapısı oluşturuldu
  - [x] Header bölümü tamamlandı
  - [x] Display bölümü tamamlandı
  - [x] Keypad bölümü tamamlandı
- [x] Hesaplama mantığı
  - [x] CalculatorService implementasyonu
  - [x] Temel matematiksel işlemler
  - [x] Hata kontrolü
  - [x] İşlem önceliği desteği
- [x] Tema sistemi
  - [x] ThemeData konfigürasyonu
  - [x] Dark/Light mode
  - [x] Sistem teması entegrasyonu
  - [x] Tema persistence

### Faz 2 - Gelişmiş Özellikler
- [x] İşlem geçmişi
  - [x] SharedPreferences ile veri depolama
  - [x] CRUD operasyonları
  - [x] Geçmiş UI implementasyonu
  - [x] Geçmişten yükleme özelliği
- [x] Çoklu dil desteği
  - [x] Easy Localization setup
  - [x] TR/EN dil dosyaları
  - [x] Dil değiştirme özelliği
  - [x] String'lerin localize edilmesi

### Faz 3 - Entegrasyonlar ve Testler
- [x] Firebase entegrasyonu
  - [x] FlutterFire setup
  - [x] Crashlytics implementasyonu
  - [x] Analytics implementasyonu
  - [x] Hata yakalama sistemi
- [x] Test implementasyonu
  - [x] Unit tests
    - [x] CalculatorService tests
    - [x] CalculatorViewModel tests
  - [x] Widget tests
    - [x] CalculatorView tests
    - [x] UI element tests
    - [x] User interaction tests
- [x] CI/CD pipeline
  - [x] GitHub Actions setup
  - [x] Automated testing
  - [x] Build & release automation
  - [x] Test coverage reporting
  - [x] Code analysis

## Klasör Yapısı
