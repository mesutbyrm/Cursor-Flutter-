/// Apple Sign-In `fullName` — yalnızca ilk girişte gelir.
class AppleFullName {
  const AppleFullName({
    this.givenName,
    this.familyName,
  });

  final String? givenName;
  final String? familyName;

  bool get isEmpty =>
      (givenName == null || givenName!.trim().isEmpty) &&
      (familyName == null || familyName!.trim().isEmpty);

  Map<String, dynamic>? toJson() {
    if (isEmpty) return null;
    return {
      if (givenName != null && givenName!.trim().isNotEmpty)
        'givenName': givenName!.trim(),
      if (familyName != null && familyName!.trim().isNotEmpty)
        'familyName': familyName!.trim(),
    };
  }

  factory AppleFullName.fromCredential({
    String? givenName,
    String? familyName,
  }) {
    return AppleFullName(
      givenName: givenName,
      familyName: familyName,
    );
  }
}
