import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/app_export.dart';
import '../../service/settings_service.dart';
import '../../routes/app_routes.dart';

class LockScreen extends StatefulWidget {
  final bool isSettingUp;
  final bool isChangingPin;

  const LockScreen({
    super.key,
    this.isSettingUp = false,
    this.isChangingPin = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
          setState(() {
            _hasError = false;
            _enteredPin = '';
          });
        }
      });

    if (!widget.isSettingUp && SettingsService.instance.isBiometricEnabled) {
      _checkBiometric();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to unlock Track Expense',
          persistAcrossBackgrounding: true,
          biometricOnly: false,
        );
        if (didAuthenticate) {
          _unlockApp();
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  void _onNumPress(String num) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += num;
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  void _verifyPin() {
    if (widget.isSettingUp || widget.isChangingPin) {
      if (!_isConfirming) {
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _firstPin = _enteredPin;
            _enteredPin = '';
            _isConfirming = true;
          });
        });
      } else {
        if (_enteredPin == _firstPin) {
          // Success!
          SettingsService.instance.setAppPin(_enteredPin);
          SettingsService.instance.setAppLockEnabled(true);
          Navigator.pop(context, true);
        } else {
          _triggerError();
        }
      }
    } else {
      // Unlocking
      if (_enteredPin == SettingsService.instance.appPin) {
        _unlockApp();
      } else {
        _triggerError();
      }
    }
  }

  void _triggerError() {
    HapticFeedback.heavyImpact();
    setState(() {
      _hasError = true;
    });
    _shakeController.forward();
  }

  void _unlockApp() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.initial);
    }
  }

  Widget _buildPinDot(int index) {
    bool isFilled = index < _enteredPin.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? (_hasError ? AppTheme.error : AppTheme.primary)
            : (isDark ? Colors.white12 : Colors.black12),
        border: isFilled
            ? null
            : Border.all(
                color: isDark ? Colors.white24 : Colors.black26,
                width: 2,
              ),
      ),
    );
  }

  Widget _buildNumPadButton(String label, {IconData? icon, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: onTap ?? () => _onNumPress(label),
          customBorder: const CircleBorder(),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.surfaceVariantDark : Colors.white,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 28, color: theme.colorScheme.onSurface)
                  : Text(
                      label,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String title = "Enter PIN";
    if (widget.isSettingUp || widget.isChangingPin) {
      title = _isConfirming ? "Confirm PIN" : "Create PIN";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: (widget.isSettingUp || widget.isChangingPin) 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox(height: 48), // Padding equivalent
            ),
            const Spacer(flex: 2),
            const Icon(
              Icons.lock_rounded,
              size: 48,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Keep your finances secure",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const Spacer(flex: 1),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shakeOffset = _hasError
                    ? sin(_shakeAnimation.value * pi) * 8
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => _buildPinDot(index)),
                  ),
                );
              },
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildNumPadButton('1'),
                      _buildNumPadButton('2'),
                      _buildNumPadButton('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumPadButton('4'),
                      _buildNumPadButton('5'),
                      _buildNumPadButton('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumPadButton('7'),
                      _buildNumPadButton('8'),
                      _buildNumPadButton('9'),
                    ],
                  ),
                  Row(
                    children: [
                      // Biometric button (only if unlocking and enabled)
                      if (!widget.isSettingUp && 
                          !widget.isChangingPin && 
                          SettingsService.instance.isBiometricEnabled)
                        _buildNumPadButton(
                          '',
                          icon: Icons.fingerprint_rounded,
                          onTap: _checkBiometric,
                        )
                      else
                        const Spacer(),
                      
                      _buildNumPadButton('0'),
                      
                      _buildNumPadButton(
                        '',
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
