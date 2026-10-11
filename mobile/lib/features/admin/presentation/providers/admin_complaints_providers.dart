import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_complaint.dart';
import 'admin_panel_providers.dart';

final adminComplaintsProvider = FutureProvider.autoDispose
    .family<AdminComplaintsPageResult, String>((ref, status) async {
  return ref.read(adminRemoteProvider).fetchComplaints(status: status);
});
