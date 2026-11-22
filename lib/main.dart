import 'package:flutter/widgets.dart';

import 'features/bank_list/bank_list_screen.dart';
import 'features/bank_list/bank_store.dart';
import 'features/bank_list/device_authenticator.dart';

export 'features/bank_list/bank_catalog.dart';
export 'features/bank_list/bank_list_screen.dart';
export 'features/bank_list/bank_store.dart';
export 'features/bank_list/device_authenticator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AllBankApp(
      store: SecureBankStore(),
      authenticator: LocalDeviceAuthenticator(),
    ),
  );
}
