import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../agency/presentation/providers/agency_providers.dart';

/// Onaylı falcı/ajans için «Panel», değilse «Ol» etiketi ve rotası.
class BranchRoleActions {
  BranchRoleActions._();

  static TellerBranchAction tellerAction(WidgetRef ref) {
    final approved = ref.watch(approvedPsychicProvider);
    final isPanelTeller = approved.valueOrNull?.isApprovedTeller == true ||
        (approved.isLoading && approved.valueOrNull?.profile?.isApproved == true);
    if (isPanelTeller) {
      return const TellerBranchAction(
        label: 'Falcı\nPanel',
        icon: Icons.dashboard_outlined,
        route: '/canli-falcilar/dashboard',
      );
    }
    return const TellerBranchAction(
      label: 'Falcı\nOl',
      icon: Icons.workspace_premium_rounded,
      nativePath: '/falci-ol',
    );
  }

  static AgencyBranchAction agencyAction(WidgetRef ref) {
    final approved = ref.watch(approvedAgencyProvider);
    final isPanelAgency = approved.isApprovedAgency ||
        (approved.loading && approved.agency?.isUsable == true);
    if (isPanelAgency) {
      return const AgencyBranchAction(
        label: 'Ajans\nPanel',
        icon: Icons.business_center_outlined,
        route: '/ajans/dashboard',
      );
    }
    return const AgencyBranchAction(
      label: 'Ajans\nOl',
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
