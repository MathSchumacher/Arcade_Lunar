import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../main_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool isPhone;
  final int? userId;

  const VerificationScreen({
    super.key,
    required this.emailOrPhone,
    required this.isPhone,
    this.userId,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  bool _isLoading = false;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _resendCountdown = 30;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
        }
      });
      
      return _resendCountdown > 0;
    });
  }

  String get _maskedContact {
    final contact = widget.emailOrPhone;
    if (widget.isPhone) {
      // Mask phone: +55 11 9****-1234
      if (contact.length > 8) {
        return '${contact.substring(0, contact.length - 4).replaceRange(contact.length > 8 ? contact.length - 8 : 0, contact.length - 4, '****')}-${contact.substring(contact.length - 4)}';
      }
    } else {
      // Mask email: c****@arcade.lunar
      final parts = contact.split('@');
      if (parts.length == 2 && parts[0].length > 2) {
        return '${parts[0][0]}${'*' * (parts[0].length - 1)}@${parts[1]}';
      }
    }
    return contact;
  }

  void _onCodeDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all filled
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _onCodeDigitBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) return;

    setState(() => _isLoading = true);

    try {
      // Try real API if userId is available
      if (widget.userId != null) {
        try {
          final response = await AuthService.verify(
            userId: widget.userId!,
            code: code,
          );
          
          if (mounted && response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Account verified!'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
            return;
          }
        } catch (apiError) {
          final errorMsg = apiError.toString();
          if (errorMsg.contains('Invalid') || errorMsg.contains('expired')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid or expired code'), backgroundColor: Colors.red),
              );
              for (var controller in _controllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            }
            return;
          }
          // Backend not available, fall through to mock
        }
      }
      
      // Mock code "1234" - Dev workaround when SMS service isn't available
      // Still tries to verify the REAL account with this code
      if (widget.userId != null && code == '1234') {
        try {
          // Try to verify with "1234" - backend should accept this in dev mode
          final response = await AuthService.verify(
            userId: widget.userId!,
            code: '1234',
          );
          
          if (mounted && response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Account verified!'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
            return;
          }
        } catch (e) {
          // Backend doesn't accept 1234, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
            );
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
          return;
        }
      }
      
      // No userId means registration failed - shouldn't reach here
      if (widget.userId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration incomplete. Please try again.'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    
    // TODO: Replace with actual API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification code resent!')),
    );
    
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isPhone ? 'AMBIENTE SEGURO' : 'VERIFICAÇÃO',
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                widget.isPhone ? Icons.verified_user : Icons.mark_email_read,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              widget.isPhone ? 'Verifique seu número' : 'Código de Acesso',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              widget.isPhone 
                  ? 'Insira o código PIN de 4 dígitos enviado para'
                  : 'Insira o código de segurança enviado para',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Contact
            Text(
              _maskedContact,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Code inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildCodeInput(index)),
            ),
            
            const SizedBox(height: 32),
            
            // Resend timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_canResend) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reenviar código em ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${_resendCountdown.toString().padLeft(2, '0')}s',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Não recebeu? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCode,
                    child: Text(
                      'Reenviar código',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Verify button
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;
    
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused 
              ? AppColors.primary 
              : hasValue 
                  ? AppColors.primary.withOpacity(0.5) 
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
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
        onSubmitted: (_) {
          if (index < 3) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
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
        onPressed: _isLoading ? null : _verifyCode,
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
                    'VERIFICAR',
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
}
