# Cursor ekranı: "Create PR" / "Review N PRs"

## Ne anlama geliyor?

- **Create PR (üst sağ):** Cloud Agent oturumunun dalı (`cursor/*` veya `claude/*`) için GitHub’da taslak/PR açılmasını önerir. Bu repoda **normal akış doğrudan `main` push**’tur (`AGENTS.md`).
- **Review N PRs (alt sol):** Cursor’un biriktirdiği **açık veya taslak PR** sayısı. GitHub’da gerçekten açık PR az olsa bile, eski agent dalları listede kalabilir.

## Ne yapmalısınız?

1. Kod **`main`**’deyse PR açmanız **zorunlu değil** — uyarıyı yok sayabilir veya PR’ı kapatıp birleşmiş sayabilirsiniz.
2. GitHub → [Pull requests](https://github.com/mesutbyrm/Cursor-Flutter-/pulls): açık taslak PR’ları **Merge** veya **Close** edin.
3. Agent talimatı: **`AGENTS.md`** — “Agent’lar PR oluşturmaz; değişiklikler `main`’e commit/push”.

## Bu depo (2026-09-27)

- Claude UI yenileme (**#394**) `main`’e alındı (`bd9efa49`, sürüm **1.0.609+660**).
- Canlı/PK/misafir/SSE işleri **605–609** CHANGELOG satırlarında.

APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
