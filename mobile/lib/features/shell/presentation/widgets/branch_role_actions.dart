import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/providers/teller_profile_provider.dart';
import '../../../agency/presentation/providers/agency_providers.dart';

/// Onaylı falcı/ajans için «Panel», değilse «Ol» etiketi ve rotası.
class BranchRoleActions {
  BranchRoleActions._();

  static TellerBranchAction tellerAction(WidgetRef ref) {
    final approved = ref.watch(approvedTellerProvider);
    if (approved.isApprovedTeller) {
      return const TellerBranchAction(
        label: 'Falcı\nPanel',
        icon: Icons.dashboard_outlined,
        route: '/canli-falcilar/dashboard',
      );
    }
    return const TellerBranchAction(
      label: 'Falcı\nol',
      icon: Icons.workspace_premium_rounded,
      nativePath: '/falci-ol',
    );
  }

  static AgencyBranchAction agencyAction(WidgetRef ref) {
    final approved = ref.watch(approvedAgencyProvider);
    if (approved.isApprovedAgency) {
      return const AgencyBranchAction(
        label: 'Ajans\nPanel',
        icon: Icons.business_center_outlined,
        route: '/ajans/dashboard',
      );
    }
    return const AgencyBranchAction(
      label: 'Ajans\nol',
      icon: Icons.business_center_rounded,
      nativePath: '/ajans-ol',
    );
  }
}

class TellerBranchAction {
  const TellerBranchAction({
    required this.label,
    required this.icon,
    this.route,
    this.nativePath,
  });

  final String label;
  final IconData icon;
  final String? route;
  final String? nativePath;

  void navigate(BuildContext context) {
    if (route != null) {
      context.push(route!);
    }
  }
}

class AgencyBranchAction {
  const AgencyBranchAction({
    required this.label,
    required this.icon,
    this.route,
    this.nativePath,
  });

  final String label;
  final IconData icon;
  final String? route;
  final String? nativePath;

  void navigate(BuildContext context) {
    if (route != null) {
      context.push(route!);
    }
  }
}
