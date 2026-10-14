import 'dart:io';

Future<bool> checkInternetAccess() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 2));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
