import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService(this._auth);

  final LocalAuthentication _auth;

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}
