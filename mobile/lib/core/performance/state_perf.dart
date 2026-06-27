import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State / Riverpod rebuild sınırları — yalnızca değişen alt ağaç yeniden çizilir.
abstract final class StatePerf {
  /// Liste öğesi kimliği — gereksiz rebuild azaltır.
  static Key itemKey(String prefix, Object id) => ValueKey('$prefix-$id');
}

/// Tek bir provider dilimini izleyen izole [ConsumerWidget].
class SelectiveConsumer<T> extends ConsumerWidget {
  const SelectiveConsumer({
    super.key,
    required this.provider,
    required this.select,
    required this.builder,
  });

  final ProviderListenable<T> provider;
  final T Function(T value) select;
  final Widget Function(BuildContext context, WidgetRef ref, T slice) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(provider.select(select));
    return builder(context, ref, slice);
  }
}
