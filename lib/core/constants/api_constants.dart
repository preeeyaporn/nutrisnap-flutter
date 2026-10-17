/// API Constants for NutriSnap services
class ApiConstants {
  ApiConstants._();

  // Open Food Facts API
  static const String openFoodFactsBaseUrl = 'https://world.openfoodfacts.org';
  static const String openFoodFactsProductEndpoint = '/api/v2/product';
  static const String openFoodFactsSearchEndpoint = '/cgi/search.pl';
  static const String openFoodFactsUserAgent = 'NutriSnap - Flutter - Version 1.0.0';

  // Gemini API
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String defaultGeminiModel = 'gemini-flash-latest';
  static const String defaultGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String geminiApiKeyPrefKey = 'nutrisnap_gemini_api_key';
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Hive Box Names
  static const String foodBoxName = 'nutrisnap_food_items';
  static const String historyBoxName = 'nutrisnap_scan_history';
  static const String userSettingsBoxName = 'nutrisnap_user_settings';
  static const String favoritesBoxName = 'nutrisnap_favorites';

  // Firestore Collections
  static const String firestoreUsersCollection = 'users';
  static const String firestoreFoodLogsCollection = 'food_logs';
  static const String firestoreFavoritesCollection = 'favorites';
}
