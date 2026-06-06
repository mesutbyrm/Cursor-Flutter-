# Neden canlifal.com’da görünmüyor?

## Kısa cevap

Bu GitHub reposu **Flutter mobil uygulama** + referans API içerir. **canlifal.com web sitesinin kaynak kodu burada yok.**  
Yaptığımız `site/jeton/` dosyaları otomatik olarak canlifal.com’a gitmez; **siz web projesine kopyalayıp deploy etmelisiniz.**

## Kontrol (şu an canlifal.com)

| URL | Durum |
|-----|--------|
| https://canlifal.com/sosyal | Var (sosyal akış çalışıyor) |
| https://canlifal.com/jeton-yukle | **404 — sayfa yok** |
| Mobil APK | Jeton mockup ekranları **uygulamada** var |

## Ne yapmalısınız?

### Jeton görselleri (WhatsApp / Papara / Havale)

1. canlifal.com **Next.js** projesini açın (Vercel/hosting’deki asıl site kodu).
2. Repodaki şu klasörü kopyalayın: **`site/canlifal-jeton-web/`**
3. `README.md` adımlarını uygulayın → route: **`/jeton-yukle`**
4. Sunucuda API uçları: `docs/CANLIFAL_COM_KURULUM.md`

### Sosyal mockup

Sosyal kısmen sitede var (`/sosyal`). Tam mockup (hikâye şeridi, composer vb.) için yine **site reposunda** ilgili React bileşenlerinin güncellenmesi gerekir; bu Flutter reposu sadece mobil + API referansı sağlar.

## Bu repoda hazır olanlar

| Konum | Ne işe yarar |
|-------|----------------|
| `site/canlifal-jeton-web/` | **canlifal.com’a yapıştırılacak** Next.js sayfaları (mockup) |
| `site/jeton/` | Statik HTML yedek (iframe ile de kullanılabilir) |
| `mobile/` | APK — jeton + sosyal mobilde |
| `api/` | Yerel test API’si |

## Destek

canlifal.com web reposunun linkini veya erişimi paylaşırsanız, aynı PR’da doğrudan o repoya da eklenebilir. Şu an yalnızca **kopyalanabilir paket** bu Flutter reposunda.
