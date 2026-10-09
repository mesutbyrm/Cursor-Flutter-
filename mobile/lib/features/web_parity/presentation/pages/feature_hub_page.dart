import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/canlifal_motion.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../domain/feature_catalog.dart';

/// «Tüm Özellikler» — web'deki her özelliğin mobil girişi.
///
/// Animasyon pilotu: kutular oturumda yalnız ilk açılışta kademeli girer
/// (en çok 5 adım), ikon bir kez zıplar, basınca küçülür. Hareket azaltılmışsa
/// ([CanlifalMotionPolicy]) hiçbiri çalışmaz. Sürekli dönen animasyon yok;
/// hepsi tek seferlik ve `flutter_animate` tarafından dispose edilir.
class FeatureHubPage extends ConsumerStatefulWidget {
  const FeatureHubPage({super.key});

  static var _entrancePlayedThisSession = false;

  @visibleForTesting
  static void resetEntranceForTest() => _entrancePlayedThisSession = false;

  @override
  ConsumerState<FeatureHubPage> createState() => _FeatureHubPageState();
}

class _FeatureHubPageState extends ConsumerState<FeatureHubPage> {
  late final bool _playEntrance;

  @override
  void initState() {
    super.initState();
    _playEntrance = !FeatureHubPage._entrancePlayedThisSession;
    FeatureHubPage._entrancePlayedThisSession = true;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = CanlifalMotionPolicy.reducedOf(context, ref);
    final animateIn = _playEntrance && !reduced;
    var index = 0;
    return MockScaffold(
      title: 'Tüm Özellikler',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
        children: [
          for (final g in kFeatureGroups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(
                g,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                for (final f in kFeatureCatalog.where((e) => e.group == g))
                  _HubTile(
                    f,
                    index: index++,
                    animateIn: animateIn,
                    reduced: reduced,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile(
    this.f, {
    required this.index,
    required this.animateIn,
    required this.reduced,
  });

  final FeatureEntry f;
  final int index;
  final bool animateIn;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    // Amblem görseli (isme uygun mistik ikon) — yoksa düz ikon.
    Widget emblem = f.image != null
        ? Image.asset(
            f.image!,
            fit: BoxFit.cover,
            cacheWidth: 240,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : Center(child: Icon(f.icon, color: Colors.white, size: 28));
    if (animateIn) {
      emblem = emblem
          .animate(
            delay:
                CanlifalMotionTokens.webStagger * index.clamp(0, 5) +
                CanlifalMotionTokens.micro,
          )
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: CanlifalMotionTokens.normalMax,
            curve: CanlifalMotionTokens.spring,
          );
    }
    final tile = CanlifalPressable(
      scale: reduced ? 1 : CanlifalMotionTokens.pressScale,
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(f.route);
      },
      child: Semantics(
        button: true,
        label: f.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  f.colors.first.withValues(alpha: 0.92),
                  f.colors.last.withValues(alpha: 0.78),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                emblem,
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xD1000000),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!animateIn) return tile;
    return CanlifalEntranceFadeSlide.staggered(index: index, child: tile);
  }
}
