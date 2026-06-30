import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Misafir kullanıcı — Google ile oturum açma kartı.
class ProfileGuestSignInCard extends ConsumerWidget {
  const ProfileGuestSignInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(authUserActionBusyProvider);

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 72,
            color: Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          const Text(
            'Misafir modundasınız',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sesli odalar, cüzdan ve profil için Google ile giriş yapın.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GoogleSignInButton(
            label: 'Google ile Giriş yap',
            busy: busy,
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .loginWithGoogle(),
          ),
        ],
      ),
    );
  }
}
