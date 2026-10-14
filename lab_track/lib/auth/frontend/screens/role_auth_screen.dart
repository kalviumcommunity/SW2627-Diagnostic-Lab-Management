import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

/// Unified, role-customized authentication screen supporting:
/// - Patient, Phlebotomist, Lab Technician, Front Desk, and Administrator
/// - Fast role-switching bar
/// - Log In vs. Sign Up mode toggling
/// - 1-Click Google Sign-In for Patients
/// - Phone OTP verification for field and patient access
/// - Role-specific metadata registration (Badge ID, Lab Section, Branch)
/// - 1-Click Instant Demo Login for all roles
class RoleAuthScreen extends StatefulWidget {
  final UserRole role;

  const RoleAuthScreen({super.key, this.role = UserRole.patient});

  @override
  State<RoleAuthScreen> createState() => _RoleAuthScreenState();
}

class _RoleAuthScreenState extends State<RoleAuthScreen> {
  final _formKey = GlobalKey<FormState>();

  late UserRole _currentRole;
  bool _isSignup = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _patientUseEmail = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '9876543210');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _badgeIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _adminPasscodeController = TextEditingController();

  // Dropdown states
  String _selectedGender = 'Female';
  String _selectedBranch = 'Downtown Spoke Center #1';
  String _selectedLabSection = 'Biochemistry & Immunoassay';

  final List<String> _branches = [
    'Downtown Spoke Center #1',
    'South City Hub Main Lab',
    'Gurugram Central Transit Hub',
    'Noida Apex Diagnostics',
  ];

  final List<String> _labSections = [
    'Biochemistry & Immunoassay',
    'Hematology & Coagulation',
    'Microbiology & Serology',
    'Pathology & Histology',
    'Molecular Diagnostics',
  ];

  @override
  void initState() {
    super.initState();
    _currentRole = widget.role;
    _prefillDemoFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _badgeIdController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _adminPasscodeController.dispose();
    super.dispose();
  }

  void _prefillDemoFields() {
    switch (_currentRole) {
      case UserRole.patient:
        _emailController.text = 'john.doe@example.com';
        _nameController.text = 'John Doe';
        _ageController.text = '38';
        _phoneController.text = '9876543210';
        _addressController.text = 'Flat 4B, Sunrise Residency, Sector 14';
        break;
      case UserRole.phlebotomist:
        _emailController.text = 'rahul.phlebo@labtrack.com';
        _nameController.text = 'Rahul Verma';
        _badgeIdController.text = 'PH-204';
        _phoneController.text = '9876511111';
        break;
      case UserRole.labTechnician:
        _emailController.text = 'sarah.labtech@labtrack.com';
        _nameController.text = 'Dr. Sarah Chen';
        _badgeIdController.text = 'LAB-501';
        _phoneController.text = '9876555555';
        break;
      case UserRole.frontDesk:
        _emailController.text = 'priya.frontdesk@labtrack.com';
        _nameController.text = 'Priya Sharma';
        _badgeIdController.text = 'FD-108';
        _phoneController.text = '9876522222';
        break;
      case UserRole.admin:
        _emailController.text = 'dr.malhotra@labtrack.com';
        _nameController.text = 'Dr. Vikram Malhotra';
        _adminPasscodeController.text = 'APEX-ADMIN-SECURE';
        _phoneController.text = '9876533333';
        break;
    }
  }

  void _selectRole(UserRole role) {
    if (_currentRole == role) return;
    setState(() {
      _currentRole = role;
      _isSignup = false;
      _prefillDemoFields();
    });
  }

  Color get _accentColor {
    switch (_currentRole) {
      case UserRole.patient:
        return AppColors.primary; // Sky Blue
      case UserRole.phlebotomist:
        return const Color(0xFFD97706); // Warm Amber
      case UserRole.labTechnician:
        return const Color(0xFF7C3AED); // Bio Purple
      case UserRole.frontDesk:
        return AppColors.accent; // Medical Teal
      case UserRole.admin:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  Color get _lightBgColor {
    switch (_currentRole) {
      case UserRole.patient:
        return AppColors.primaryLight;
      case UserRole.phlebotomist:
        return const Color(0xFFFEF3C7);
      case UserRole.labTechnician:
        return const Color(0xFFF3E8FF);
      case UserRole.frontDesk:
        return AppColors.accentLight;
      case UserRole.admin:
        return const Color(0xFFEEF2FF);
    }
  }

  IconData get _roleIcon {
    switch (_currentRole) {
      case UserRole.patient:
        return Icons.person_rounded;
      case UserRole.phlebotomist:
        return Icons.vaccines_rounded;
      case UserRole.labTechnician:
        return Icons.science_rounded;
      case UserRole.frontDesk:
        return Icons.desk_rounded;
      case UserRole.admin:
        return Icons.insights_rounded;
    }
  }

  String get _roleSubtitle {
    switch (_currentRole) {
      case UserRole.patient:
        return 'Diagnostic test booking, tracking & report downloads';
      case UserRole.phlebotomist:
        return 'Doorstep specimen collection, barcoding & temperature logs';
      case UserRole.labTechnician:
        return 'Accessioning, rack intake, analyzers & quality control';
      case UserRole.frontDesk:
        return 'Walk-in requisitions, instant search & label dispatch';
      case UserRole.admin:
        return 'SLA governance, TAT analytics & fleet supervision';
    }
  }

  String get _demoPersonaName {
    switch (_currentRole) {
      case UserRole.patient:
        return 'John Doe (Patient)';
      case UserRole.phlebotomist:
        return 'Rahul Verma (#PH-204)';
      case UserRole.labTechnician:
        return 'Dr. Sarah Chen (#LAB-501)';
      case UserRole.frontDesk:
        return 'Priya Sharma (Desk #1)';
      case UserRole.admin:
        return 'Dr. Vikram Malhotra (HQ)';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(role: _currentRole);
    if (!mounted) return;
    if (success) {
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      _showError(auth.errorMessage);
    }
  }

  Future<void> _handleDemoLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginAsRole(_currentRole);
    if (!mounted) return;
    if (success) {
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      _showError(auth.errorMessage);
    }
  }

  Future<void> _handlePhoneOtpLogin() async {
    final phone = '+91${_phoneController.text.trim()}';
    if (_phoneController.text.trim().length != 10) {
      _showError('Enter a valid 10-digit mobile number.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone, role: _currentRole);
    if (!mounted) return;
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: phone),
        ),
      );
    } else {
      _showError(auth.errorMessage);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    bool success;
    if (_isSignup) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match. Please verify.');
        return;
      }
      success = await auth.signUpWithCredentials(
        role: _currentRole,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: '+91${_phoneController.text.trim()}',
        assignedBranchId: _selectedBranch,
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        address: _addressController.text.trim(),
      );
    } else {
      success = await auth.loginWithCredentials(
        role: _currentRole,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    if (success) {
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      _showError(auth.errorMessage);
    }
  }

  void _showError(String? message) {
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${_currentRole.displayName} Portal',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Role Switcher Strip
                  _buildRoleSelectorStrip(),
                  const SizedBox(height: 20),

                  // 2. Main Authentication Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role Header
                          _buildRoleHeader(),
                          const SizedBox(height: 22),

                          // Mode Switcher (Log in / Sign up)
                          _buildModeSwitcher(),
                          const SizedBox(height: 24),

                          // Role-Specific Content
                          if (!_isSignup)
                            _buildLoginBody(auth)
                          else
                            _buildSignupBody(auth),

                          const SizedBox(height: 24),

                          // 1-Click Demo Shortcut Footer
                          _buildDemoAccessFooter(auth),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Security & Trust Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 14, color: AppColors.textTertiary),
                      SizedBox(width: 6),
                      Text(
                        'LabTrack Diagnostic HIPAA & NABL Compliant Auth',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildRoleSelectorStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: UserRole.values.map((role) {
          final isSelected = _currentRole == role;
          Color roleColor = AppColors.primary;
          if (role == UserRole.phlebotomist) roleColor = const Color(0xFFD97706);
          if (role == UserRole.labTechnician) roleColor = const Color(0xFF7C3AED);
          if (role == UserRole.frontDesk) roleColor = AppColors.accent;
          if (role == UserRole.admin) roleColor = const Color(0xFF4F46E5);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _selectRole(role),
              selectedColor: roleColor,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? roleColor : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _lightBgColor,
            shape: BoxShape.circle,
            border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(_roleIcon, color: _accentColor, size: 30),
        ),
        const SizedBox(height: 12),
        Text(
          '${_currentRole.displayName} Access',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _roleSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignup = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSignup ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isSignup
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !_isSignup ? FontWeight.w800 : FontWeight.w600,
                    color: !_isSignup ? _accentColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignup = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSignup ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isSignup
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isSignup ? FontWeight.w800 : FontWeight.w600,
                    color: _isSignup ? _accentColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Login Body ---

  Widget _buildLoginBody(AuthProvider auth) {
    if (_currentRole == UserRole.patient && !_patientUseEmail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Google Sign-In Button
          OutlinedButton(
            onPressed: auth.isLoading ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Divider
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR MOBILE OTP',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),

          // Mobile Phone Number Input
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '98765 00000',
              prefixText: '+91  ',
              prefixIcon: Icon(Icons.phone_android_rounded),
              counterText: '',
            ),
            validator: (v) =>
                v != null && v.trim().length == 10 ? null : 'Enter 10-digit mobile number',
          ),
          const SizedBox(height: 16),

          // Send OTP Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _handlePhoneOtpLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send Login OTP',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Switch to Email Login
          Center(
            child: TextButton(
              onPressed: () => setState(() => _patientUseEmail = true),
              child: Text(
                'Sign in with Email & Password instead',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Standard Credentials Login (Phlebotomist, Lab Tech, Front Desk, Admin, or Patient Email)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _getEmailLabel(),
            hintText: 'name@labtrack.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email address',
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Sign In as ${_currentRole.displayName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        if (_currentRole == UserRole.patient && _patientUseEmail) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _patientUseEmail = false),
              child: Text(
                'Back to Google & Mobile OTP Sign-in',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Sign Up Body ---

  Widget _buildSignupBody(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name Field
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name *',
            hintText: 'e.g. Ananya Patel',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Enter full name',
        ),
        const SizedBox(height: 12),

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address *',
            hintText: 'ananya@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email address',
        ),
        const SizedBox(height: 12),

        // Mobile Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Mobile number *',
            hintText: '98765 00000',
            prefixText: '+91  ',
            prefixIcon: Icon(Icons.phone_outlined),
            counterText: '',
          ),
          validator: (v) =>
              v != null && v.trim().length == 10 ? null : 'Enter 10-digit mobile number',
        ),
        const SizedBox(height: 12),

        // Role-Specific Inputs
        ..._buildRoleSpecificSignupInputs(),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Create password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => v != null && v.length >= 6 ? null : 'Must be at least 6 characters',
        ),
        const SizedBox(height: 12),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm password *',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
        ),
        const SizedBox(height: 20),

        // Submit Sign-Up Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Create ${_currentRole.displayName} Account',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRoleSpecificSignupInputs() {
    switch (_currentRole) {
      case UserRole.patient:
        return [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    hintText: '34',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedGender = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Home / Specimen pickup address',
              hintText: 'Flat 202, Royal Palms, Sector 21',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 12),
        ];

      case UserRole.phlebotomist:
        return [
          TextFormField(
            controller: _badgeIdController,
            decoration: const InputDecoration(
              labelText: 'Employee Badge / Phlebo ID *',
              hintText: 'e.g. PH-208',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Enter Badge ID',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBranch,
            decoration: const InputDecoration(
              labelText: 'Assigned Collection Hub',
              prefixIcon: Icon(Icons.hub_outlined),
            ),
            items: _branches
                .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedBranch = v);
            },
          ),
          const SizedBox(height: 12),
        ];

      case UserRole.labTechnician:
        return [
          TextFormField(
            controller: _badgeIdController,
            decoration: const InputDecoration(
              labelText: 'Technician License / Cert ID *',
              hintText: 'e.g. TECH-LIC-8890',
              prefixIcon: Icon(Icons.card_membership_outlined),
            ),
            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Enter License ID',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedLabSection,
            decoration: const InputDecoration(
              labelText: 'Laboratory Department',
              prefixIcon: Icon(Icons.biotech_outlined),
            ),
            items: _labSections
                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedLabSection = v);
            },
          ),
          const SizedBox(height: 12),
        ];

      case UserRole.frontDesk:
        return [
          TextFormField(
            controller: _badgeIdController,
            decoration: const InputDecoration(
              labelText: 'Desk Terminal / Counter ID',
              hintText: 'e.g. DESK-COUNTER-02',
              prefixIcon: Icon(Icons.desktop_windows_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBranch,
            decoration: const InputDecoration(
              labelText: 'Branch Center Location',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: _branches
                .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedBranch = v);
            },
          ),
          const SizedBox(height: 12),
        ];

      case UserRole.admin:
        return [
          TextFormField(
            controller: _adminPasscodeController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Executive Admin Authorization Key *',
              hintText: 'Security passkey required for admin role',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Enter authorization key',
          ),
          const SizedBox(height: 12),
        ];
    }
  }

  Widget _buildDemoAccessFooter(AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'QUICK DEMO ACCESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : _handleDemoLogin,
          icon: Icon(Icons.flash_on_rounded, size: 16, color: _accentColor),
          label: Text(
            '1-Click Instant Demo as $_demoPersonaName',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            side: BorderSide(color: _accentColor.withOpacity(0.4), width: 1.2),
            backgroundColor: _lightBgColor.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  String _getEmailLabel() {
    switch (_currentRole) {
      case UserRole.patient:
        return 'Patient Email';
      case UserRole.phlebotomist:
        return 'Phlebotomist Work Email';
      case UserRole.labTechnician:
        return 'Lab Tech Staff Email';
      case UserRole.frontDesk:
        return 'Front Desk Counter Email';
      case UserRole.admin:
        return 'Admin Corporate Email';
    }
  }
}
