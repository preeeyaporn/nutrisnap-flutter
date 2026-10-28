import 'connectivity_checker_stub.dart'
    if (dart.library.io) 'connectivity_checker_io.dart'
    if (dart.library.html) 'connectivity_checker_web.dart';

class ConnectivityChecker {
  static Future<bool> checkInternet() => checkInternetAccess();
}
