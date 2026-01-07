import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/falling_stars.dart';
import 'reset_password_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';

/// Forgot Password Screen
/// User enters email or phone, receives 4-digit code
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _isPhoneInput = false;
  String? _countryCode = '+55';
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {
      _errorMessage = null;
      final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      _isPhoneInput = cleanValue.isNotEmpty && 
          (cleanValue.startsWith('+') || RegExp(r'^[0-9]+$').hasMatch(cleanValue));
    });
  }

  String _getCompleteInput() {
    final input = _controller.text.trim();
    if (_isPhoneInput && !input.startsWith('+')) {
      return '$_countryCode$input';
    }
    return input;
  }

  Future<void> _handleSendCode() async {
    final input = _getCompleteInput();
    
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Email ou telefone é obrigatório');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.forgotPassword(emailOrPhone: input);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                userId: data['userId'] ?? 0,
                method: data['method'] ?? (_isPhoneInput ? 'sms' : 'email'),
                destination: data['destination'] ?? input,
              ),
            ),
          );
        } else if (response['success'] == true) {
          // Security response (user may not exist but we don't reveal that)
          setState(() => _errorMessage = 'Se uma conta existir, um código foi enviado para o email/telefone informado.');
        } else {
          setState(() => _errorMessage = response['error'] ?? 'Falha ao enviar código');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        
        if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
          errorMessage = 'Não foi possível conectar ao servidor. Verifique sua conexão.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'O servidor demorou para responder. Tente novamente.';
        }
        
        setState(() => _errorMessage = errorMessage);
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
                  
                  const SizedBox(height: 40),
                  
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Digite seu email ou telefone para receber um código de recuperação',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
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
                  
                  // Input field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        if (_isPhoneInput)
                          CountryCodePicker(
                            onChanged: (c) => setState(() => _countryCode = c.dialCode),
                            initialSelection: 'BR',
                            favorite: const ['+55', 'BR'],
                            backgroundColor: AppColors.surface,
                            dialogBackgroundColor: AppColors.surface,
                            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Icon(Icons.mail_outline, color: AppColors.textSecondary),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: _onInputChanged,
                            keyboardType: _isPhoneInput 
                                ? TextInputType.phone 
                                : TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email ou Telefone',
                              hintStyle: TextStyle(color: AppColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Send button
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
                      onPressed: _isLoading ? null : _handleSendCode,
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
                                  'ENVIAR CÓDIGO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.send, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Back to login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Voltar ao login',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
