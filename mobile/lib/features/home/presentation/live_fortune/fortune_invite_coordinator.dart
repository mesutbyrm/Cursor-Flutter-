/// Falcı davet popup'ını push/SSE sonrası zorla göstermek için köprü.
class FortuneInviteCoordinator {
  FortuneInviteCoordinator._();

  static void Function()? onRequestPresent;

  static void requestPresent() => onRequestPresent?.call();
}
