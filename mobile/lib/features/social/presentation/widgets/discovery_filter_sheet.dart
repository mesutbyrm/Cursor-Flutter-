import 'package:flutter/material.dart';

import '../../../../core/design_system/cds.dart';

/// Tanış keşif filtreleri — tek ortak sheet.
class DiscoveryFilterState {
  const DiscoveryFilterState({
    this.minAge = 18,
    this.maxAge = 60,
    this.maxDistanceKm = 50,
    this.onlineOnly = false,
    this.interestQuery = '',
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final bool onlineOnly;
  final String interestQuery;

  DiscoveryFilterState copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    bool? onlineOnly,
    String? interestQuery,
  }) {
    return DiscoveryFilterState(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      interestQuery: interestQuery ?? this.interestQuery,
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
  late TextEditingController _interests;

  @override
  void initState() {
    super.initState();
    _minAge = widget.initial.minAge;
    _maxAge = widget.initial.maxAge;
    _distance = widget.initial.maxDistanceKm;
    _onlineOnly = widget.initial.onlineOnly;
    _interests = TextEditingController(text: widget.initial.interestQuery);
  }

  @override
  void dispose() {
    _interests.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      DiscoveryFilterState(
        minAge: _minAge,
        maxAge: _maxAge,
        maxDistanceKm: _distance,
        onlineOnly: _onlineOnly,
        interestQuery: _interests.text.trim(),
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
            Text('Maks. mesafe: $_distance km'),
            Slider(
              value: _distance.toDouble(),
              min: 5,
              max: 200,
              divisions: 39,
              label: '$_distance km',
              onChanged: (v) => setState(() => _distance = v.round()),
            ),
            SwitchListTile(
              title: const Text('Yalnızca çevrimiçi'),
              value: _onlineOnly,
              onChanged: (v) => setState(() => _onlineOnly = v),
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
    );
  }
}
