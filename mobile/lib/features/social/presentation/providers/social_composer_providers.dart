import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App bar + butonundan inline composer'ı açmak için sinyal.
final socialComposerExpandedProvider = StateProvider<bool>((ref) => false);
