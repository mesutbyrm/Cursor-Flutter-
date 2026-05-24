import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../messages/data/datasources/messages_remote_datasource.dart';

/// Destek kullanıcısına kullanıcı adıyla mesaj gönderir.
class ProfileHelpSupportPage extends ConsumerStatefulWidget {
  const ProfileHelpSupportPage({super.key});

  @override
  ConsumerState<ProfileHelpSupportPage> createState() =>
      _ProfileHelpSupportPageState();
}

class _ProfileHelpSupportPageState extends ConsumerState<ProfileHelpSupportPage> {
  final _messageCtrl = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<String?> _resolveSupportUserId() async {
    const supportUsername = String.fromEnvironment(
      'SUPPORT_USERNAME',
      defaultValue: 'destek',
    );
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.userLookup(supportUsername),
      );
      final body = res.data ?? {};
      final data = body['data'] is Map ? asJsonMap(body['data']) : body;
      final user = data['user'] is Map ? asJsonMap(data['user']) : data;
      return pick(user, ['id'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _send() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      final supportId = await _resolveSupportUserId();
      if (supportId == null) {
        throw const ApiException(
          'Destek hesabı bulunamadı. Lütfen daha sonra tekrar deneyin.',
        );
      }

      final fullMessage =
          'Destek talebi — @${user.username}\n\n$text';

      await MessagesRemoteDataSource(ref.read(dioProvider))
          .send(supportId, fullMessage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesajınız destek ekibine iletildi')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Yardım & Destek',
          subtitle: 'Mesajınız kullanıcı adınızla gider',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Text(
                'Merhaba ${user?.display ?? ""}, sorununuzu yazın. '
                'Ekibimiz @${user?.username ?? "kullanici"} bilgisiyle yanıtlar.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İletişim: ${Env.siteOrigin}/destek',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Mesajınız',
                  alignLabelWithHint: true,
                  hintText: 'Sorun, öneri veya ödeme bildirimi detayı…',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
