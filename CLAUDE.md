# Hesap Makinesi (com.akidesoft.calc)

Flutter hesap makinesi, yalnızca Android olarak Google Play'de yayında (AkideSoft). Kullanıcıyla Türkçe konuş; kod yorumları ve CHANGELOG Türkçe, commit mesajları İngilizce.

## Yapı
- `lib/core/` (DI: `get_it`, tema, Firebase), `lib/features/{calculator,feedback,support}/`.
- **Hesap mantığı `calculator_view.dart` içindeki `_CalculatorViewState`'tedir.** `CalculatorViewModel` `main.dart`'ta sağlanır ama hesap ekranı onu kullanmaz; hesap davranışını değiştirirken view'daki kodu düzenle.
- İç ifade `*` ve `/` kullanır; ekranda `×` `÷` gösterilir (`_displayChar`). Yazılan sayı `double`'a çevrilmeden gösterilir (`_formatNumberString`): `5.` ve `5.0` kaybolmamalı. Sonuçlar 10 haneye yuvarlanır.
- Metinler `easy_localization`: `assets/translations/{tr,en,es,zh,hi}.json`. Yeni her metin **5 dosyaya da** eklenir, kodda `.tr()` kullanılır.
- Destek: kalp butonu ödüllü reklamı doğrudan açar (`AdService`); destek/satın alma penceresi menüden açılır. Web/masaüstü için `*_stub.dart` dosyaları bozulmamalı.

## Geri bildirim ve Firestore
- Form `calculator_feedback` koleksiyonuna yazar (paylaşılan `feedback-appss` projesi). Kural yalnızca `type` = `bug` veya `suggestion` kabul eder; `FeedbackService.firestoreType` formdaki türleri buna çevirir. Alan adları kuralla birebir aynı kalmalı (`test/feedback_rules_compat_test.dart` bunu sabitler).
- **Repodaki `firestore.rules` canlı kurallarla uyuşmuyor.** Canlı kuralları değiştirmeden ya da repodaki dosyayı yayınlamadan önce kullanıcıya sor; yanlış deploy diğer uygulamaların kurallarını bozar.

## Komutlar
```bash
flutter analyze lib test
flutter test                      # test/widget_test.dart eski ve başarısız; yeni testler geçmeli
flutter build appbundle --release # Play için; çıktı build/app/outputs/bundle/release/app-release.aab
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
flutter emulators --launch Medium_Phone_API_36.1
```
- Flutter komutları `analysis_options.yaml` ve `ios/Flutter/*` dosyalarını kendiliğinden değiştirir; commit'e alma, `git checkout analysis_options.yaml ios/Flutter` ile geri al. `ios/Flutter/ephemeral/` altındaki dosyalar commit edilmez.
- Release imzası `android/key.properties`'ten gelir (repoda yok, gizli). Emülatörde farklı imzalı sürüm varsa `adb uninstall com.akidesoft.calc` gerekir.

## Sürüm
- Play yüklemesi için `pubspec.yaml` `version` (ad+kod) her yüklemede artar; aynı `versionCode` reddedilir. Sürümle birlikte `CHANGELOG.md`'ye kayıt eklenir.
- Gradle, AGP ve Kotlin sürümleri Flutter'ın minimumuna bağlıdır; Flutter güncellenince build hata verirse `android/settings.gradle.kts` ve `gradle-wrapper.properties` kontrol edilir.

## Diğer
- `site/` tanıtım sayfasıdır (`index.html` + `assets/`, 5 dil). `web/index.html` Flutter web'e aittir, ona dokunma.
- Commit ve push yalnızca kullanıcı isteyince yapılır.
