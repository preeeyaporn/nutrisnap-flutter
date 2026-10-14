import 'package:http/http.dart' as http;

Future<bool> checkInternetAccess() async {
  try {
    final res = await http
        .get(Uri.parse('https://clients3.google.com/generate_204'))
        .timeout(const Duration(seconds: 2));
    return res.statusCode == 204 || res.statusCode == 200;
  } catch (_) {
    return false;
  }
}
