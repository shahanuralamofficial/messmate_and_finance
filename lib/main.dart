import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/market_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/mess_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/security_screen.dart';
import 'screens/recurring_screen.dart';
import 'screens/planning_screen.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Initialize Notifications
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settings, theme, _) {
          return MaterialApp(
            title: 'Messmate & Finance',
            debugShowCheckedModeBanner: false,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('bn', 'BD'),
              Locale('en', 'US'),
            ],
            home: const SplashScreen(),
            routes: {
              '/lockscreen': (ctx) => const LockScreen(), // Add LockScreen route
              '/login': (ctx) => const LoginScreen(),
              '/home': (ctx) => const HomeScreen(),
              '/profile': (ctx) => const ProfileScreen(),
              '/settings': (ctx) => const SettingsScreen(),
              '/accounts': (ctx) => const AccountsScreen(),
              '/reports': (ctx) => const ReportsScreen(),
              '/market': (ctx) => const MarketScreen(),
              '/notes': (ctx) => const NotesScreen(),
              '/mess': (ctx) => const MessScreen(),
              '/tools': (ctx) => const ToolsScreen(),
              '/budgets': (ctx) => const BudgetScreen(),
              '/debts': (ctx) => const DebtsScreen(),
              '/savings': (ctx) => const SavingsScreen(),
              '/security': (ctx) => const SecurityScreen(),
              '/recurring': (ctx) => const RecurringScreen(),
              '/planning': (ctx) => const PlanningScreen(),
              '/transactions': (ctx) => const Scaffold(body: Center(child: Text('Transactions Screen'))),
            },
          );
        },
      ),
    );
  }
}
