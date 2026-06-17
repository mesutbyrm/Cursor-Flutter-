/// Misafir modu — yayın grid düzeni.
enum LiveGuestLayout {
  solo(1, 'Tek kişi'),
  duo(2, '2 kişi'),
  trio(3, '3 kişi'),
  quad(4, '4 kişi');

  const LiveGuestLayout(this.seats, this.label);

  final int seats;
  final String label;
}
