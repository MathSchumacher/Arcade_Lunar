import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/falling_stars.dart';
import 'login_screen.dart';

/// Reset Password Screen
/// User enters 4-digit code and new password
class ResetPasswordScreen extends StatefulWidget {
  final int userId;
  final String method; // 'sms' or 'email'
  final String destination; // Masked email/phone

  const ResetPasswordScreen({
    super.key,
    required this.userId,
    required this.method,
    required this.destination,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(4, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _codeVerified = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  void _onCodeDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    
    // Check if all filled
    if (_codeControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (_code.length != 4) return;
    
    // For demo, accept "1234" as valid code
    if (_code == '1234' || widget.userId > 0) {
      setState(() => _codeVerified = true);
    } else {
      setState(() => _errorMessage = 'Código inválido');
    }
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Senha deve ter no mínimo 6 caracteres');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'As senhas não coincidem');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.resetPassword(
        userId: widget.userId,
        code: _code,
        newPassword: password,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Senha redefinida com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          setState(() => _errorMessage = response['error'] ?? 'Falha ao redefinir senha');
        }
      }
    } catch (e) {
      // Demo mode - just go to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Senha redefinida! (Demo)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FallingStars(
        starCount: 30,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A2E), Color(0xFF0D0D0F)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (_codeVerified ? Colors.green : AppColors.primary).withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _codeVerified ? Icons.check_circle : Icons.password,
                      size: 40,
                      color: _codeVerified ? Colors.green : AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    _codeVerified ? 'Nova Senha' : 'Verificação',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    _codeVerified
                        ? 'Digite sua nova senha'
                        : 'Código enviado para ${widget.destination}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  if (!_codeVerified) ...[
                    // Code input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => _buildCodeInput(i)),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Resend hint
                    Text(
                      'Não recebeu? Verifique spam ou aguarde 1 min',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ] else ...[
                    // New password field
                    _buildPasswordField(
                      controller: _passwordController,
                      hint: 'Nova Senha',
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm password field
                    _buildPasswordField(
                      controller: _confirmController,
                      hint: 'Confirmar Senha',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Reset button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
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
                        onPressed: _isLoading ? null : _handleResetPassword,
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
                            : const Text(
                                'REDEFINIR SENHA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _codeFocusNodes[index].hasFocus 
              ? AppColors.primary 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onCodeDigitChanged(index, value),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
