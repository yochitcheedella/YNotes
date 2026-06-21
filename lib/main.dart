import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/security/auto_lock_service.dart';
import 'auth/auth_provider.dart';
import 'presentation/providers/diary_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/pin_setup_screen.dart';
import 'presentation/screens/pin_login_screen.dart';

import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://ojzctwtvocuabudmvqlt.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qemN0d3R2b2N1YWJ1ZG12cWx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NDIxNTIsImV4cCI6MjA5NzUxODE1Mn0.PhmF27J31XwyIvgRJJgbE4ZMop8EceDVRS195g-tuTw',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    AppLogger.info("Supabase successfully initialized.");
  } catch (e) {
    AppLogger.warning("Supabase initialization failed: $e. Running in offline/secure local storage mode.");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: const DiaroApp(),
    ),
  );
}

class DiaroApp extends StatefulWidget {
  const DiaroApp({super.key});

  @override
  State<DiaroApp> createState() => _DiaroAppState();
}

class _DiaroAppState extends State<DiaroApp> {
  
  @override
  void initState() {
    super.initState();
    _setupSupabaseAuth();
  }

  void _setupSupabaseAuth() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        AppLogger.info("Supabase session restored: ${session.user.id}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Diaro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      
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
        '/pin-setup': (context) => const PinSetupScreen(),
        '/pin-login': (context) => const PinLoginScreen(),
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

    // Initialize AutoLockService
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    AutoLockService.instance.initialize(
      initialDuration: authProvider.autoLockDuration,
      onLockTriggered: () {
        if (authProvider.isAuthenticated && authProvider.hasPin) {
          authProvider.lock();
          _checkLockRedirection();
        }
      },
    );
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
    if (!authProvider.isAuthenticated || !authProvider.hasPin) return;

    if (state == AppLifecycleState.paused) {
      AutoLockService.instance.pause();
    } else if (state == AppLifecycleState.resumed) {
      AutoLockService.instance.resume();
      _checkLockRedirection();
    }
  }

  void _checkLockRedirection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else if (authProvider.isLocked) {
      Navigator.of(context).pushNamedAndRemoveUntil('/pin-login', (route) => false);
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
        if (authProvider.isAuthenticated && authProvider.hasPin) {
          AutoLockService.instance.recordInteraction();
        }
      },
      child: widget.child,
    );
  }
}
