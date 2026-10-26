import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/database/local/hive_food_repository.dart';
import 'core/database/cloud/firestore_food_repository.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/open_food_facts_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'features/nutrition/presentation/providers/nutrition_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Cloud Services
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize Hive Local Database
  try {
    await Hive.initFlutter();
    HiveFoodRepository.isInitialized = true;
    FirebaseAuthServiceImpl.isHiveInitialized = true;
  } catch (e) {
    debugPrint('Hive initialization notice: $e');
  }

  // Initialize Services & Repositories
  final savedApiKey = await GeminiServiceImpl.getSavedApiKey();
  final activeApiKey = (savedApiKey != null && savedApiKey.trim().isNotEmpty)
      ? savedApiKey.trim()
      : null;
  if (activeApiKey != null) {
    GeminiServiceImpl.setGlobalApiKey(activeApiKey);
  }

  final authService = FirebaseAuthServiceImpl();
  final openFoodFactsService = OpenFoodFactsServiceImpl();
  final geminiService = GeminiServiceImpl(apiKey: activeApiKey);
  final localFoodRepo = HiveFoodRepository();
  final cloudFoodRepo = FirestoreFoodRepository(userId: 'default_user');

  final nutrisnapRepository = NutriSnapRepositoryImpl(
    localRepository: localFoodRepo,
    cloudRepository: cloudFoodRepo,
    openFoodFactsService: openFoodFactsService,
    geminiService: geminiService,
  );

  runApp(
    NutriSnapApp(authService: authService, repository: nutrisnapRepository),
  );
}

class NutriSnapApp extends StatelessWidget {
  final FirebaseAuthService? authService;
  final NutriSnapRepositoryImpl? repository;

  const NutriSnapApp({super.key, this.authService, this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NutritionProvider>(
          create: (_) => NutritionProvider(repository: repository),
          update: (_, authProvider, nutritionProvider) {
            final user = authProvider.currentUser;
            if (user != null) {
              final effectiveId = (user.email != null && user.email!.contains('@'))
                  ? user.email!.trim()
                  : user.id;
              nutritionProvider?.updateUserInfo(
                newUserId: effectiveId,
                email: user.email,
                displayName: user.displayName,
                dailyTarget: user.dailyCalorieTarget,
              );
            }
            return nutritionProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'NutriSnap - โภชนาการอัจฉริยะ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.primaryDark,
            surface: Colors.white,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: AppTypography.heading1.fontFamily,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
        ),
        builder: (context, child) {
          // Layout builder to support optional centered standard mobile preview (390x844)
          // on wide displays (web/desktop) while remaining fully native and responsive on mobile devices
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Scaffold(
                  backgroundColor: const Color(0xFF0F172A),
                  body: Center(
                    child: Container(
                      width: 390,
                      height: 844,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
