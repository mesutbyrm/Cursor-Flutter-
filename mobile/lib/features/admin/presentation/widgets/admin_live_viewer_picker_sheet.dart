import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/data/datasources/live_field/live_field_online_users_api.dart';

/// Admin — yayın izleyici listesi (`GET /api/live/online-users`).
Future<LiveFieldOnlineUser?> showAdminLiveViewerPicker({
  required BuildContext context,
  required WidgetRef ref,
  required String streamId,
  String roomType = 'live',
}) async {
  final api = LiveFieldOnlineUsersApi(ref.read(dioProvider));
  List<LiveFieldOnlineUser> users = [];
  String? error;

  try {
    final page = await api.fetchOnlineUsers(
      roomId: streamId,
      roomType: roomType,
      limit: 100,
    );
    users = page.users;
    if (users.isEmpty && roomType == 'live') {
      final voicePage = await api.fetchOnlineUsers(
        roomId: streamId,
        roomType: 'video',
        limit: 100,
      );
      users = voicePage.users;
    }
  } catch (e) {
    error = ApiException.userMessage(e);
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<LiveFieldOnlineUser>(
    context: context,
    backgroundColor: const Color(0xFF1A0F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      if (error != null) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error!, textAlign: TextAlign.center),
        );
      }
      if (users.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'İzleyici listesi boş veya API henüz veri döndürmedi.',
            textAlign: TextAlign.center,
          ),
        );
      }
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'İzleyici seç',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  final name = u.userName ?? u.nickname ?? u.userId;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      u.userId,
                      style: const TextStyle(fontSize: 10),
                    ),
                    onTap: () => Navigator.pop(ctx, u),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
