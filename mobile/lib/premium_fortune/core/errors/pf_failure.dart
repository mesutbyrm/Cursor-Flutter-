import 'package:equatable/equatable.dart';

sealed class PfFailure extends Equatable {
  const PfFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PfAuthFailure extends PfFailure {
  const PfAuthFailure(super.message);
}

final class PfNetworkFailure extends PfFailure {
  const PfNetworkFailure(super.message);
}

final class PfInsufficientCreditsFailure extends PfFailure {
  const PfInsufficientCreditsFailure([
    super.message = 'Yetersiz kredi. Lütfen cüzdanınızı yükleyin.',
  ]);
}

final class PfAiFailure extends PfFailure {
  const PfAiFailure(super.message);
}

final class PfStorageFailure extends PfFailure {
  const PfStorageFailure(super.message);
}

final class PfPaymentFailure extends PfFailure {
  const PfPaymentFailure(super.message);
}
