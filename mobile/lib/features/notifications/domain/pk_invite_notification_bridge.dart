/// PK davet bildirimi / push tıklaması — sayfa yönlendirmesi yerine global dinleyici.
abstract final class PkInviteNotificationBridge {
  static void Function()? onInviteTapped;

  static void notifyInviteTapped() {
    onInviteTapped?.call();
  }
}
