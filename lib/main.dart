import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/firebase_service.dart';
import 'core/constants/app_theme.dart';
import 'core/security/auto_lock_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/diary_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';

import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseService.instance.markInitialized();
    AppLogger.info("Firebase successfully initialized.");
  } catch (e) {
    AppLogger.warning("Firebase initialization failed: $e. Running in offline/secure local storage mode.");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: const YNoteApp(),
    ),
  );
}

class YNoteApp extends StatelessWidget {
  const YNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'YNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      
      // Global builder to wrap the entire app in pointer interaction listeners & lifecycle observers
      builder: (context, child) {
        return AppInteractionAndLifecycleWrapper(
          child: child ?? const SizedBox(),
        );
      },
      
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

// Wrapper to monitor touch activities and OS lifecycle states
class AppInteractionAndLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppInteractionAndLifecycleWrapper({super.key, required this.child});

  @override
  State<AppInteractionAndLifecycleWrapper> createState() => _AppInteractionAndLifecycleWrapperState();
}

class _AppInteractionAndLifecycleWrapperState extends State<AppInteractionAndLifecycleWrapper> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Monitor application state (Backgrounding vs Foregrounding)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    if (state == AppLifecycleState.paused) {
      AutoLockService.instance.pause();
    } else if (state == AppLifecycleState.resumed) {
      AutoLockService.instance.resume();
      _checkLockRedirection();
    }
  }

  void _checkLockRedirection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // If the timer locked the session, pop all routes and redirect to the login screen
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // Record user touch interaction globally
        // Resets the inactivity timer whenever the user touches anywhere in the viewport
        if (authProvider.isAuthenticated) {
          AutoLockService.instance.recordInteraction();
        }
      },
      child: widget.child,
    );
  }
}
