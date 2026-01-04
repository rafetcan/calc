# Hesap Makinesi Uygulaması PRD

## 1. Ürün Özeti
Modern, çok dilli ve kullanıcı dostu bir hesap makinesi uygulaması. Temel matematiksel işlemlerin yanı sıra, işlem geçmişi görüntüleme, karanlık mod desteği ve hata bildirimi özellikleri sunacaktır.

## 2. Hedefler
- Kullanıcılara basit ve kullanışlı bir hesap makinesi deneyimi sunmak
- Çoklu dil desteği ile uluslararası kullanıcılara hitap etmek
- Kullanıcı deneyimini iyileştirmek için hata raporlama sistemi oluşturmak
- Responsive tasarım ile tüm cihazlarda sorunsuz çalışmasını sağlamak

## 3. Teknik Özellikler

### 3.1 Mimari
- MVVM (Model-View-ViewModel) mimari pattern'i kullanılacak
- Dependency Injection kullanılacak
- Repository pattern ile veri yönetimi sağlanacak

### 3.2 Temel Özellikler
1. Matematiksel İşlemler:
   - Toplama, çıkarma, çarpma, bölme
   - Yüzde hesaplama
   - Karekök alma
   - Hafıza fonksiyonları (M+, M-, MR, MC)

2. İşlem Geçmişi:
   - Son yapılan işlemlerin listesi
   - Geçmiş işlemleri temizleme
   - Geçmişteki işlemleri tekrar kullanabilme

3. Çoklu Dil Desteği:
   - İngilizce ve Türkçe dil seçenekleri
   - Cihaz diline göre otomatik dil seçimi
   - Dil değiştirme özelliği

4. Tema Desteği:
   - Açık/Koyu tema seçeneği
   - Sistem temasına göre otomatik tema değişimi
   - Manuel tema değiştirme özelliği

5. Hata Bildirimi:
   - Firebase Crashlytics entegrasyonu
   - Kullanıcı geri bildirimi formu
   - Hata raporlarının yönetimi

## 4. Kullanıcı Arayüzü Gereksinimleri

### 4.1 Responsive Tasarım
- Tüm ekran boyutlarına uyumlu tasarım
- Portrait ve landscape modlarında düzgün çalışma
- Tablet ve iPad desteği
- Dinamik font boyutları

### 4.2 Ana Ekran Bileşenleri
- Sonuç ekranı
- Sayısal tuş takımı
- İşlem tuşları
- Geçmiş görüntüleme butonu
- Ayarlar menüsü
- Tema değiştirme butonu

## 5. Veri Yönetimi
- İşlem geçmişi için local storage kullanımı
- Kullanıcı tercihlerinin (dil, tema) saklanması
- Firebase entegrasyonu için config yönetimi

## 6. Test Gereksinimleri
- Unit testler
- UI testleri
- Entegrasyon testleri
- Kullanıcı kabul testleri

## 7. Güvenlik Gereksinimleri
- Firebase güvenlik kuralları
- Veri şifreleme
- Hata ayıklama loglarının güvenliği

## 8. Performans Gereksinimleri
- Hızlı başlatma süresi (<2 saniye)
- Anlık işlem tepki süresi (<100ms)
- Düşük bellek kullanımı
- Pil tüketiminin optimizasyonu

## 9. Gelecek Geliştirmeler
- Bilimsel hesap makinesi modu
- Birim dönüştürücü
- Widget desteği
- Bulut senkronizasyonu

## 10. Proje Zaman Çizelgesi
1. Faz 1 (2 hafta):
   - Temel hesap makinesi fonksiyonları
   - MVVM mimarisi kurulumu
   - Responsive UI tasarımı

2. Faz 2 (2 hafta):
   - Çoklu dil desteği
   - Tema sistemi
   - İşlem geçmişi

3. Faz 3 (1 hafta):
   - Firebase entegrasyonu
   - Hata bildirimi sistemi
   - Test ve optimizasyon 