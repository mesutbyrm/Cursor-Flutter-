# Canlifal Design System (CDS) v1

**Konum:** `mobile/lib/core/design_system/`

## Kullanım

```dart
import 'package:canlifal_social/core/design_system/cds.dart';
```

- **Renk / tipografi:** `CdsColors`, `CdsTypography`
- **Spacing / radius:** `CdsSpacing`, `CdsRadius` (= `AppSpacing`)
- **Bileşenler:** `CdsButton`, `CdsCard`, `CdsBottomSheet.show`, `CdsDialog.confirm`
- **Durumlar:** `CdsLoading`, `CdsEmpty`, `CdsError`
- **Performans:** `cdsFxProvider` — `performanceMode` dekoratif FX'i kapatır

## Migration

1. Yeni UI yalnızca CDS.
2. Mevcut `showPremiumBottomSheet` → `CdsBottomSheet.show` (aynı implementasyon).
3. Ham `Colors.*` toplu replace **yapılmaz** — ekran ekran.

## Legacy

- `CanlifalTokens`, `Premium2026Tokens` tema extension olarak kalır; CDS bunların üstünde semantik katman.
