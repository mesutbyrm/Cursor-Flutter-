import 'package:flutter/material.dart';

/// Profil düzeni — her zaman tek sütun (katman çakışması önlenir).
class ProfilePageLayout extends StatelessWidget {
  const ProfilePageLayout({
    super.key,
    required this.header,
    required this.stats,
    required this.quickActions,
    required this.wallet,
    required this.premium,
    required this.publisher,
    required this.teller,
    required this.admin,
    required this.content,
    required this.settings,
    this.showAdmin = false,
    this.showPublisher = false,
  });

  final Widget header;
  final Widget stats;
  final Widget quickActions;
  final Widget wallet;
  final Widget premium;
  final Widget publisher;
  final Widget teller;
  final Widget admin;
  final Widget content;
  final Widget settings;
  final bool showAdmin;
  final bool showPublisher;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      header,
      const SizedBox(height: 16),
      stats,
      const SizedBox(height: 20),
      if (showAdmin) ...[
        admin,
        const SizedBox(height: 22),
      ],
      wallet,
      const SizedBox(height: 22),
      premium,
      const SizedBox(height: 22),
      quickActions,
      const SizedBox(height: 22),
      teller,
      if (showPublisher) ...[
        publisher,
        const SizedBox(height: 22),
      ],
      content,
      const SizedBox(height: 22),
      settings,
    ];

    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
