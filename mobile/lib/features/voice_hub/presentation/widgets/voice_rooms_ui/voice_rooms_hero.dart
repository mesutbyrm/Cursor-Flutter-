import 'package:flutter/material.dart';

/// Hero geçişinde kaynak widget'ı yeniden kullan — ek layout + overdraw azaltır.
class VoiceRoomsHero extends StatelessWidget {
  const VoiceRoomsHero({
    super.key,
    required this.tag,
    required this.child,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final shuttle = flightDirection == HeroFlightDirection.push
            ? fromHeroContext.widget
            : toHeroContext.widget;
        return Material(
          type: MaterialType.transparency,
          child: shuttle,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
