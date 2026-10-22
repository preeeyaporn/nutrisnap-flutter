import 'dart:io';

Future<bool> checkInternetAccess() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }
  try {
    final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
    socket.destroy();
    return true;
  } catch (_) {
    try {
      final socket = await Socket.connect('1.1.1.1', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          final socket = await Socket.connect(result[0], 443, timeout: const Duration(seconds: 2));
          socket.destroy();
          return true;
        }
      } catch (_) {}
      return false;
    }
  }
}

