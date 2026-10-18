# Calculator App

Modern, çok dilli ve kullanıcı dostu bir Flutter hesap makinesi uygulaması.

## Özellikler

- 📱 Responsive tasarım
- 🌙 Dark/Light mode desteği
- 🌍 Çoklu dil desteği (TR/EN/ZH/ES/Hİ)
- 🧮 Toplama, çıkarma, çarpma (×), bölme (÷), yüzde (%) ve parantez
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

## Geri Bildirim Analizi (Ekim 2026)

Firestore `calculator_feedback` koleksiyonundaki 256 kullanıcı mesajı (ağırlıklı olarak sürüm 1.1.3, Ocak–Ekim 2026) incelendi. Mesajların çoğu İspanyolca, ardından Türkçe ve İngilizce.

| Grup | Mesaj | Oran |
|---|---|---|
| Çözülen konular (× ÷ % ve yuvarlama) | ~111 | %43 |
| Kalan, ele alınabilir istekler | ~48 | %19 |
| Övgü, anlamsız veya alakasız mesaj | ~97 | %38 |

Anlamlı geri bildirimlerin yaklaşık %70'i bu sürümde karşılandı, %30'u sırada.

### Bulgular

| Konu | Mesaj | Kök neden |
|---|---|---|
| Çarpma işareti bulunamıyor | ~69 | Tuş `*` etiketiyle çiziliyordu, kullanıcılar tanımadı |
| Bölme işareti bulunamıyor | ~28 | Tuş `/` etiketiyle çiziliyordu |
| Yüzde (%) yok | ~19 | Tuş hiç yoktu |
| Ondalık nokta, binlik ayracı karışıklığı | ~13 | Ondalık ve binlik ayracı cihaz diline bakmıyor |
| Canlı sonuç isteği | ~13 | Sonuç yalnızca `=` ile gösteriliyor |
| Yavaş açılış / tepki | ~10 | Ölçülmedi |
| 14.6699999, 7.1999 gibi sonuçlar | ~8 | `double` artıkları yuvarlanmıyordu |
| Tuş boyutu | ~8 | Bir kısım büyük, bir kısım küçük istiyor |
| Renk / tema | ~4 | |
| Geçmiş silme, bellek | ~4 | |
| "Error" hatası | ~5 | Tekrar üretilemedi |
| Reklamsız olması övgüsü | ~5 | Reklamsız deneyim bir artı |

### Yapılanlar (sürüm 1.1.4 adayı)

- [x] Tuşlar `×` ve `÷` olarak gösterilir (ekran ve geçmiş); iç ifade değişmedi
- [x] `%` tuşu eklendi (sonek yüzde: `50%` = 0.5, `200×10%` = 20)
- [x] Sonuçlar 10 haneye yuvarlanır (`6.13+8.54` = 14.67, `6×1.2` = 7.2)
- [x] Google Play Billing Library 8.0.0 (`in_app_purchase` 3.3.1)
- [x] Android derleme araçları Flutter 3.47 için yükseltildi (Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20)
- [x] Kalp butonu ödüllü reklamı doğrudan açar (pencere yok); destek penceresi menüden erişilir
- [x] Widget testleri (`test/calculator_view_test.dart`)

### Yapılabilecekler (öncelik sırasıyla)

1. Ondalık ve binlik ayracını cihaz diline göre seçmek (ES/TR: ondalık virgül)
2. İfadenin altında canlı sonuç önizlemesi
3. `200+10%` davranışı: şu an 200,1; birçok hesap makinesi 220 verir
4. Geçmiş ekranına "temizle"
5. Tuş boyutu, renk ve tema seçenekleri; tuş sesi ve titreşim ayarı
6. Açılış ve tepki süresi ölçümü
7. "Error" durumunda ifadeyi Crashlytics'e log'lamak
8. Geri bildirim formunda tür seçimini varsayılansız yapmak ("bug" varsayılan olduğu için masum yorumlar da bug sayılıyor)

### Notlar

- Yeni sürümden gelen mesajları ayırmak için Firestore'daki `appVersion` alanı kullanılabilir; koleksiyonu silmeye gerek yok.
- Google Play: Veri Güvenliği formu Play Console'dan güncel tutulmalıdır (Firestore e-posta/mesaj/cihaz bilgisi, Crashlytics, Analytics, AdMob, Play Faturalandırma).

## Klasör Yapısı
