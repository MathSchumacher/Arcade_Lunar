import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../../../core/theme/app_colors.dart';
import '../../../utils/content_moderator.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/falling_stars.dart';
import 'verification_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Registration Screen with full user data collection
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _countryCode = '+55';
  DateTime? _dateOfBirth; // HIDDEN - Keeping for future use
  String? _avatarPath;
  Uint8List? _avatarBytes;
  String _verificationMethod = 'sms'; // 'sms' or 'whatsapp'
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {

    _usernameController.dispose();

    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate username using UsernameValidator
  String? _validateUsername(String username) {
    return UsernameValidator.validate(username);
  }

  int? _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarPath = image.path;
          _avatarBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Photo selected!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting photo: $e')),
        );
      }
    }
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarPath = image.path;
          _avatarBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Photo captured!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }


  /// Show photo selection bottom sheet
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escolher foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final phone = '$_countryCode${_phoneController.text.trim()}';
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await AuthService.register(
        email: email.isNotEmpty ? email : null,
        phone: phone,
        password: password,
        username: username.isNotEmpty ? username : null,
      );
      
      final userId = response['data']?['userId'];
      
      if (userId == null) {
        throw Exception('Registration failed - no user ID returned');
      }
      
      // Show verification code from API in dev mode
      final code = response['data']?['verificationCode'];
      if (code != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEV: Verification code is $code'), backgroundColor: Colors.blue),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              emailOrPhone: phone,
              isPhone: true,
              userId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (mounted) {
        if (errorMsg.contains('already exists')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account already exists with this email or phone'), backgroundColor: Colors.red),
          );
        } else if (errorMsg.contains('fetch') || 
                   errorMsg.contains('connection') || 
                   errorMsg.contains('socket') ||
                   errorMsg.contains('timeout') ||
                   errorMsg.contains('network')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot connect to server. Please check your internet connection.'), backgroundColor: Colors.red),
          );
        } else if (errorMsg.contains('invalid') || errorMsg.contains('validation')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please check your information and try again.'), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $errorMsg'), backgroundColor: Colors.red),
          );
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
        starCount: 30,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0A2E),
                Color(0xFF0D0D0F),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Back button
                    IconButton(
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

                    const SizedBox(height: 20),

                    // Title
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ).createShader(bounds),
                        child: const Text(
                          'CRIAR CONTA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'Junte-se à comunidade Arcade Lunar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Avatar picker
                    _buildAvatarPicker(),

                    const SizedBox(height: 24),



                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Username required';
                        // Use content moderator for inappropriate content check
                        final error = _validateUsername(v);
                        return error;
                      },
                    ),

                    // HIDDEN: Date of Birth (simplified registration)
                    // const SizedBox(height: 16),
                    // _buildDatePicker(),

                    const SizedBox(height: 16),

                    // Phone
                    _buildPhoneField(),

                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email obrigatório';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Senha',
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Senha deve ter pelo menos 8 caracteres';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return 'Inclua pelo menos uma letra maiúscula';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Inclua pelo menos um número';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Senha',
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Senhas não coincidem';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),



                    // Age warning for minors
                    if (_dateOfBirth != null && _calculateAge(_dateOfBirth!)! < 18)
                      _buildMinorWarning(),

                    const SizedBox(height: 24),

                    // Register button
                    _buildRegisterButton(),

                    const SizedBox(height: 16),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Já tem conta? ',
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            children: [
                              TextSpan(
                                text: 'Entrar',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: _avatarPath != null ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
                image: _avatarBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_avatarBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarBytes == null
                  ? Icon(Icons.add_a_photo, size: 40, color: AppColors.textSecondary)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(_avatarPath != null ? Icons.edit : Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                  : 'Data de Nascimento',
              style: TextStyle(
                color: _dateOfBirth != null ? Colors.white : AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (_dateOfBirth != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_calculateAge(_dateOfBirth!)} anos',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Country code picker
          CountryCodePicker(
            onChanged: (country) => setState(() => _countryCode = country.dialCode!),
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
          ),
          Container(width: 1, height: 30, color: AppColors.primary.withOpacity(0.2)),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Telefone',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Telefone obrigatório';
                if (v.length < 10) return 'Telefone inválido';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildMinorWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menores de 18 anos terão acesso restrito a conteúdo adulto e chat filtrado.',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
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
        onPressed: _isLoading ? null : _handleRegister,
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
                    'CRIAR CONTA',
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
