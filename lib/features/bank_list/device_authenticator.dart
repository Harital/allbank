import 'package:local_auth/local_auth.dart';

abstract interface class DeviceAuthenticator {
  Future<bool> authenticate(String reason);
}

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> authenticate(String reason) =>
      _auth.authenticate(localizedReason: reason);
}
