import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'data/services/auth_service.dart';

void main() {
  // CRITICAL: Must be called before any other Flutter calls
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ensure status bar style is correct
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1A1F), // AppColors.surface
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcade Lunar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that checks auth state and routes accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final loggedIn = await AuthService.isLoggedIn();
      
      // If logged in, verify token is still valid with backend
      if (loggedIn) {
        try {
          final user = await AuthService.getMe();
          if (user == null) {
            // Token invalid or expired, clear and show login
            await AuthService.clearSession();
            if (mounted) {
              setState(() {
                _isLoggedIn = false;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          // Backend not reachable, still show login for safety
          await AuthService.clearSession();
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Any error, show login screen
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0F),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

