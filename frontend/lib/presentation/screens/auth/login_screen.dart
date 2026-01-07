import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/services/facebook_auth_service.dart';
import '../../widgets/falling_stars.dart';
import 'verification_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneInput = false;
  String? _countryCode = '+55';
  
  // Elegant error message system
  String? _errorMessage;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Detect if input is phone or email
  void _onInputChanged(String value) {
    setState(() {
      _errorMessage = null; // Clear error on input
      // Check if it's a phone number
      final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      _isPhoneInput = cleanValue.isNotEmpty && 
          (cleanValue.startsWith('+') || 
           RegExp(r'^[0-9]+$').hasMatch(cleanValue));
    });
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  /// Validate phone format
  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Must have country code + 10-11 digits
    return RegExp(r'^\+[1-9]\d{10,14}$').hasMatch(cleaned);
  }

  /// Get the complete phone with country code
  String _getCompletePhone() {
    final input = _emailPhoneController.text.trim();
    if (input.startsWith('+')) {
      return input;
    }
    return '$_countryCode$input';
  }

  /// Handle login
  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Manual validation with elegant error messages
    final input = _emailPhoneController.text.trim();
    final password = _passwordController.text;

    if (input.isEmpty && password.isEmpty) {
      setState(() => _errorMessage = 'Email/Phone and Password are required');
      return;
    }
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Email or Phone is required');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailOrPhone = _isPhoneInput 
          ? _getCompletePhone() 
          : input;
      
      // Call real backend API
      final response = await AuthService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      
      if (mounted) {
        if (response['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          setState(() => _errorMessage = response['error'] ?? 'Login failed');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        
        // User-friendly error messages
        if (errorMsg.contains('invalid credentials') || 
            errorMsg.contains('not found') ||
            errorMsg.contains('user not found')) {
          setState(() => _errorMessage = 'Account not found. Check your email/phone or create an account.');
        } else if (errorMsg.contains('password') || errorMsg.contains('incorrect')) {
          setState(() => _errorMessage = 'Incorrect password. Please try again.');
        } else if (errorMsg.contains('fetch') || 
                   errorMsg.contains('connection') || 
                   errorMsg.contains('socket') ||
                   errorMsg.contains('timeout') ||
                   errorMsg.contains('network')) {
          setState(() => _errorMessage = 'Cannot connect to server. Please check your internet connection.');
        } else if (errorMsg.contains('not verified')) {
          setState(() => _errorMessage = 'Account not verified. Please check your email/SMS.');
        } else {
          setState(() => _errorMessage = 'Login failed. Please try again later.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FallingStars(
        starCount: 40,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0A2E), // Dark purple top
                Color(0xFF0D0D0F), // Dark bottom
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo with glow effect
                    _buildLogo(),
                    
                    const SizedBox(height: 24),
                    
                    // App name
                    _buildAppTitle(),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    Text(
                      'CONNECT . EXPLORE . TRANSCEND',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Error message card
                    _buildErrorCard(),
                    
                    // Email/Phone input
                    _buildEmailPhoneField(),
                    
                    const SizedBox(height: 16),
                    
                    // Password input
                    _buildPasswordField(),
                    
                    const SizedBox(height: 12),
                    
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login button
                    _buildLoginButton(),
                    
                    const SizedBox(height: 16),
                    
                    // Register button
                    _buildRegisterButton(),
                    
                    const SizedBox(height: 32),
                    
                    // Social login divider
                    _buildDivider(),
                    
                    const SizedBox(height: 24),
                    
                    // Social buttons (visual only)
                    _buildSocialButtons(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  /// Elegant animated error card (matching design specification)
  Widget _buildErrorCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _errorMessage != null ? 60 : 0,
      margin: EdgeInsets.only(bottom: _errorMessage != null ? 16 : 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _errorMessage != null ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1B1E), // Dark red background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6B3539), // Red border
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Error icon with circular background
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B3539),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE57373),
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              // Error message text
              Expanded(
                child: Text(
                  _errorMessage ?? '',
                  style: const TextStyle(
                    color: Color(0xFFE0B4B4),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close button
              GestureDetector(
                onTap: () => setState(() => _errorMessage = null),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFE0B4B4),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF9B5DE5), // Purple
          Color(0xFF00F5D4), // Cyan
          Color(0xFFE0AAFF), // Light purple
        ],
      ).createShader(bounds),
      child: const Text(
        'ARCADE LUNAR',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmailPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Country code picker (shows only for phone)
          if (_isPhoneInput)
            CountryCodePicker(
              onChanged: (country) => setState(() => _countryCode = country.dialCode),
              initialSelection: 'BR',
              favorite: const ['+55', 'BR', '+1', 'US'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
              backgroundColor: AppColors.surface,
              dialogBackgroundColor: AppColors.surface,
              textStyle: const TextStyle(color: Colors.white, fontSize: 14),
              dialogTextStyle: const TextStyle(color: Colors.white),
              searchStyle: const TextStyle(color: Colors.white),
              searchDecoration: InputDecoration(
                hintText: 'Search country',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.mail_outline,
                color: AppColors.textSecondary,
              ),
            ),
          
          Expanded(
            child: TextFormField(
              controller: _emailPhoneController,
              onChanged: _onInputChanged,
              keyboardType: _isPhoneInput 
                  ? TextInputType.phone 
                  : TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isPhoneInput ? 'Phone Number' : 'Email or Phone Number',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (_isPhoneInput) {
                  if (!_isValidPhone(_getCompletePhone())) {
                    return 'Invalid phone format';
                  }
                } else {
                  if (!_isValidEmail(value)) {
                    return 'Invalid email format';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password required';
          }
          if (value.length < 6) {
            return 'Min 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REGISTER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONNECT WITH',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google button
        _buildSocialButton(
          icon: 'G',
          color: const Color(0xFFDB4437),
          onTap: _handleGoogleSignIn,
        ),
        const SizedBox(width: 20),
        // Facebook button
        _buildSocialButton(
          icon: 'f',
          color: const Color(0xFF4267B2),
          onTap: _handleFacebookSignIn,
        ),
      ],
    );
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await FacebookAuthService.signIn();
      
      if (mounted && response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no login: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await GoogleAuthService.signIn();
      
      if (mounted && response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no login: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton({required String icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
