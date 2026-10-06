import 'package:flutter/foundation.dart';
import '../../../domain/enums/user_role.dart';
import '../../../data/models/user_model.dart';
import '../../backend/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  String? _pendingPhoneNumber;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;
  String? get pendingPhoneNumber => _pendingPhoneNumber;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginAsRole(UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInAsRole(role);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsDemoPatient() async {
    return loginAsRole(UserRole.patient);
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _pendingPhoneNumber = phoneNumber;
    notifyListeners();

    bool success = false;
    await _authRepository.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verId) {
        _verificationId = verId;
        _isLoading = false;
        success = true;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err;
        _isLoading = false;
        success = false;
        notifyListeners();
      },
    );

    return success;
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null && smsCode != '123456') {
      _errorMessage = 'No verification ID found. Please request a new OTP.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.verifyOtp(
        verificationId: _verificationId ?? 'demo-id',
        smsCode: smsCode,
        phoneNumber: _pendingPhoneNumber ?? '',
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final saved = await _authRepository.saveProfile(updatedUser);
      _currentUser = saved;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    _currentUser = null;
    _verificationId = null;
    _pendingPhoneNumber = null;
    notifyListeners();
  }
}
