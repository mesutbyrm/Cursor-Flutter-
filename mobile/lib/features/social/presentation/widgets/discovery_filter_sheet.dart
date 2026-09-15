import 'package:flutter/material.dart';

import '../../../../core/design_system/cds.dart';

/// Tanış keşif filtreleri — sunucu sorgusu + istemci yedek filtre.
class DiscoveryFilterState {
  const DiscoveryFilterState({
    this.minAge = 18,
    this.maxAge = 60,
    this.maxDistanceKm = 50,
    this.onlineOnly = false,
    this.goldOnly = false,
    this.interestQuery = '',
    this.city = '',
    this.gender = '',
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final bool onlineOnly;
  final bool goldOnly;
  final String interestQuery;
  final String city;
  final String gender;

  DiscoveryFilterState copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    bool? onlineOnly,
    bool? goldOnly,
    String? interestQuery,
    String? city,
    String? gender,
  }) {
    return DiscoveryFilterState(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      goldOnly: goldOnly ?? this.goldOnly,
      interestQuery: interestQuery ?? this.interestQuery,
      city: city ?? this.city,
      gender: gender ?? this.gender,
    );
  }
}

Future<DiscoveryFilterState?> showDiscoveryFilterSheet(
  BuildContext context, {
  required DiscoveryFilterState initial,
}) {
  return CdsBottomSheet.show<DiscoveryFilterState>(
    context: context,
    child: _DiscoveryFilterSheetBody(initial: initial),
  );
}

class _DiscoveryFilterSheetBody extends StatefulWidget {
  const _DiscoveryFilterSheetBody({required this.initial});

  final DiscoveryFilterState initial;

  @override
  State<_DiscoveryFilterSheetBody> createState() =>
      _DiscoveryFilterSheetBodyState();
}

class _DiscoveryFilterSheetBodyState extends State<_DiscoveryFilterSheetBody> {
  late int _minAge;
  late int _maxAge;
  late int _distance;
  late bool _onlineOnly;
  late bool _goldOnly;
  late TextEditingController _interests;
  late TextEditingController _city;
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _minAge = widget.initial.minAge;
    _maxAge = widget.initial.maxAge;
    _distance = widget.initial.maxDistanceKm;
    _onlineOnly = widget.initial.onlineOnly;
    _goldOnly = widget.initial.goldOnly;
    _interests = TextEditingController(text: widget.initial.interestQuery);
    _city = TextEditingController(text: widget.initial.city);
    _gender = widget.initial.gender;
  }

  @override
  void dispose() {
    _interests.dispose();
    _city.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      DiscoveryFilterState(
        minAge: _minAge,
        maxAge: _maxAge,
        maxDistanceKm: _distance,
        onlineOnly: _onlineOnly,
        goldOnly: _goldOnly,
        interestQuery: _interests.text.trim(),
        city: _city.text.trim(),
        gender: _gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CdsSpacing.lg,
          CdsSpacing.md,
          CdsSpacing.lg,
          CdsSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Keşif filtreleri', style: CdsTypography.title(context)),
              const SizedBox(height: CdsSpacing.lg),
              Text('Yaş: $_minAge – $_maxAge'),
              RangeSlider(
                values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                min: 18,
                max: 80,
                divisions: 62,
                onChanged: (v) {
                  setState(() {
                    _minAge = v.start.round();
                    _maxAge = v.end.round();
                  });
                },
              ),
              Text('Maks. mesafe (istemci): $_distance km'),
              Slider(
                value: _distance.toDouble(),
                min: 5,
                max: 200,
                divisions: 39,
                label: '$_distance km',
                onChanged: (v) => setState(() => _distance = v.round()),
              ),
              TextField(
                controller: _city,
                decoration: const InputDecoration(
                  labelText: 'Şehir (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gender.isEmpty ? null : _gender,
                decoration: const InputDecoration(labelText: 'Cinsiyet / tercih'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Fark etmez')),
                  DropdownMenuItem(value: 'female', child: Text('Kadın')),
                  DropdownMenuItem(value: 'male', child: Text('Erkek')),
                  DropdownMenuItem(value: 'other', child: Text('Diğer')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? ''),
              ),
              SwitchListTile(
                title: const Text('Yalnızca çevrimiçi'),
                value: _onlineOnly,
                onChanged: (v) => setState(() => _onlineOnly = v),
              ),
              SwitchListTile(
                title: const Text('Gold üyeler'),
                subtitle: const Text('Sunucu + istemci filtre'),
                value: _goldOnly,
                onChanged: (v) => setState(() => _goldOnly = v),
              ),
              TextField(
                controller: _interests,
                decoration: const InputDecoration(
                  labelText: 'İlgi alanı (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: CdsSpacing.lg),
              CdsButton(
                label: 'Uygula',
                onPressed: _apply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
