import 'package:flutter/material.dart';

/// Responsive profil düzeni — telefon / tablet / geniş ekran.
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

  static const _tabletBreakpoint = 720.0;
  static const _wideBreakpoint = 1000.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= _wideBreakpoint) {
      return _WideLayout(
        header: header,
        stats: stats,
        quickActions: quickActions,
        wallet: wallet,
        premium: premium,
        publisher: publisher,
        teller: teller,
        admin: admin,
        content: content,
        settings: settings,
      );
    }

    if (width >= _tabletBreakpoint) {
      return _TabletLayout(
        header: header,
        stats: stats,
        quickActions: quickActions,
        wallet: wallet,
        premium: premium,
        publisher: publisher,
        teller: teller,
        admin: admin,
        content: content,
        settings: settings,
      );
    }

    return _PhoneLayout(
      header: header,
      stats: stats,
      quickActions: quickActions,
      wallet: wallet,
      premium: premium,
      publisher: publisher,
      teller: teller,
      admin: admin,
      content: content,
      settings: settings,
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        stats,
        const SizedBox(height: 20),
        quickActions,
        const SizedBox(height: 22),
        wallet,
        const SizedBox(height: 22),
        premium,
        const SizedBox(height: 22),
        publisher,
        const SizedBox(height: 22),
        teller,
        admin,
        const SizedBox(height: 22),
        content,
        const SizedBox(height: 22),
        settings,
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        stats,
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  quickActions,
                  const SizedBox(height: 22),
                  wallet,
                  const SizedBox(height: 22),
                  content,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  premium,
                  const SizedBox(height: 22),
                  publisher,
                  const SizedBox(height: 22),
                  teller,
                  admin,
                  const SizedBox(height: 22),
                  settings,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 16),
        stats,
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  premium,
                  const SizedBox(height: 22),
                  settings,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  quickActions,
                  const SizedBox(height: 22),
                  wallet,
                  const SizedBox(height: 22),
                  content,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  publisher,
                  const SizedBox(height: 22),
                  teller,
                  admin,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
