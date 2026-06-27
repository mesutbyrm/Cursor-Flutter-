/// PK modu — bire bir veya takım.
enum PkBattleMode {
  oneVsOne,
  team;

  String get label => switch (this) {
        PkBattleMode.oneVsOne => '1v1',
        PkBattleMode.team => 'Takım',
      };
}

/// PK tur durumu.
enum PkBattlePhase {
  ready,
  active,
  finished,
}

/// Kazanan taraf.
enum PkBattleWinner {
  none,
  left,
  right,
  tie,
}
