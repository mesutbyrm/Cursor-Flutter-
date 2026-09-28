/// Sosyal sekme üst sekmeleri — test ve acceptance sözleşmesi.
/// İlk sekme ("Tümü") akışın kendisidir; diğerleri ilgili sayfaya gider.
const socialDiscoverShortcutLabels = <String>[
  'Tümü',
  'Takip',
  'Falcılar',
  'Ünlüler',
  'Fan Club',
];

/// Sosyal sekme rotaları — "Tümü" için boş (akışta kalır).
const socialDiscoverShortcutRoutes = <String>[
  '',
  '/profile/following',
  '/canli-falcilar',
  '/celebrities-hub',
  '/fan-club-hub',
];
