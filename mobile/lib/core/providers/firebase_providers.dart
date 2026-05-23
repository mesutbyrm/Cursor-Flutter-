import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';

final firebaseReadyProvider = Provider<bool>((ref) => FirebaseBootstrap.isReady);
