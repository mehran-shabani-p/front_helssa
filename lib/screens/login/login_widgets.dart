// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// --- رنگ‌های سبز ---
class LoginColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFF0D4F3C);
}

class LoginMainContent extends StatelessWidget {
  final bool hasStoredCredentials, isVerifying, isLoading, canResendCode, obscureCode;
  final int resendCooldown;
  final TextEditingController phoneController, codeController;
  final GlobalKey<FormState> phoneFormKey, verificationFormKey;
  final FocusNode phoneFocusNode, codeFocusNode;
  final VoidCallback onRegisterPhone, onVerifyCode, onLogout, resendCode;
  final Animation<double> fadeAnimation;
  final Color primaryColor;
  final String? Function(String?) validatePhone;
  final String? Function(String?) validateVerificationCode;
  final Function(bool) setObscureCode;

  const LoginMainContent({
    super.key,
    required this.hasStoredCredentials,
    required this.isVerifying,
    required this.isLoading,
    required this.phoneController,
    required this.codeController,
    required this.phoneFormKey,
    required this.verificationFormKey,
    required this.phoneFocusNode,
    required this.codeFocusNode,
    required this.onRegisterPhone,
    required this.onVerifyCode,
    required this.onLogout,
    required this.canResendCode,
    required this.resendCooldown,
    required this.resendCode,
    required this.obscureCode,
    required this.setObscureCode,
    required this.fadeAnimation,
    required this.primaryColor,
    required this.validatePhone,
    required this.validateVerificationCode,
  });

  // ✅ بهبود محاسبه ارتفاع
  double _getContainerHeight() {
    if (hasStoredCredentials) {
      return 240.0; // کمی افزایش برای logout
    } else if (isVerifying) {
      return 450.0; // افزایش قابل توجه برای verification
    } else {
      return 360.0; // افزایش برای phone input
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24, 
            vertical: MediaQuery.of(context).size.height * 0.08 // ✅ کاهش padding
          ),
          child: Column(
            children: [
              // ✅ حذف AnimatedContainer و استفاده از Container ساده
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: _getContainerHeight(),
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // ✅ حداکثر ارتفاع
                ),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: _getContainerHeight(),
                  borderRadius: 20,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15), 
                      Colors.white.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      LoginColors.lightGreen.withOpacity(0.5), 
                      LoginColors.softGreen.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: hasStoredCredentials
                        ? _buildLogoutContent()
                        : (isVerifying ? _buildVerificationContent() : _buildPhoneInputContent()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutContent() => Padding(
    key: const ValueKey('logout'),
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LoginColors.lightGreen.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: LoginColors.lightGreen, size: 28),
        ),
        const SizedBox(height: 12),
        const Text(
          'شما وارد شده‌اید', 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 22,
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 6),
        Text(
          'شماره تلفن: ${phoneController.text}', 
          style: TextStyle(color: Colors.white70, fontSize: 14)
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 8,
              shadowColor: Colors.redAccent.withOpacity(0.5),
            ),
            child: const Text(
              'خروج', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPhoneInputContent() => Padding(
    key: const ValueKey('phoneInput'),
    padding: const EdgeInsets.all(16), // ✅ کاهش padding
    child: SingleChildScrollView( // ✅ اضافه کردن scroll
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: phoneFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LoginColors.lightGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_android, color: LoginColors.lightGreen, size: 24), // ✅ کاهش سایز
            ),
            const SizedBox(height: 8), // ✅ کاهش spacing
            const Text(
              'به هلسا خوش آمدید', 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20, // ✅ کاهش فونت
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 4), // ✅ کاهش spacing
            Text(
              'لطفا شماره موبایل خود را وارد کنید', 
              style: TextStyle(color: Colors.white70, fontSize: 13), // ✅ کاهش فونت
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // ✅ کاهش spacing
            _buildPhoneInput(),
            const SizedBox(height: 16), // ✅ کاهش spacing
            _buildSubmitButton(onRegisterPhone, 'ثبت نام'),
          ],
        ),
      ),
    ),
  );

  Widget _buildPhoneInput() => Container(
    height: 56, // ✅ ارتفاع ثابت
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: phoneFocusNode.hasFocus 
          ? LoginColors.lightGreen 
          : LoginColors.softGreen.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: TextFormField(
      controller: phoneController,
      focusNode: phoneFocusNode,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        color: Colors.white, 
        fontSize: 16,
        letterSpacing: 1.2
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.phone_android, 
          color: phoneFocusNode.hasFocus 
            ? LoginColors.lightGreen 
            : Colors.white70,
          size: 20,
        ),
        hintText: '09xxxxxxxxx',
        hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validatePhone,
    ),
  );

  Widget _buildVerificationContent() => Padding(
    key: const ValueKey('verify'),
    padding: const EdgeInsets.all(16), // ✅ کاهش padding
    child: FadeTransition(
      opacity: fadeAnimation,
      child: SingleChildScrollView( // ✅ اضافه کردن scroll
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: verificationFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVerificationHeader(),
              const SizedBox(height: 16), // ✅ کاهش spacing
              _buildVerificationCodeInput(),
              const SizedBox(height: 16), // ✅ کاهش spacing
              _buildSubmitButton(onVerifyCode, 'تایید'),
              const SizedBox(height: 12), // ✅ کاهش spacing
              _buildResendButton(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildVerificationHeader() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(10), // ✅ کاهش padding
        decoration: BoxDecoration(
          color: LoginColors.lightGreen.withOpacity(0.2), 
          shape: BoxShape.circle
        ),
        child: Icon(Icons.message_rounded, color: LoginColors.lightGreen, size: 24), // ✅ کاهش سایز
      ),
      const SizedBox(height: 12), // ✅ کاهش spacing
      const Text(
        'کد تایید', 
        style: TextStyle(
          color: Colors.white, 
          fontSize: 20, // ✅ کاهش فونت
          fontWeight: FontWeight.bold
        )
      ),
      const SizedBox(height: 6), // ✅ کاهش spacing
      Text(
        'کد تایید به شماره ${phoneController.text} ارسال شد', 
        textAlign: TextAlign.center, 
        style: TextStyle(color: Colors.white70, fontSize: 13) // ✅ کاهش فونت
      ),
    ],
  );

  Widget _buildVerificationCodeInput() => Container(
    height: 60, // ✅ ارتفاع ثابت
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: codeFocusNode.hasFocus 
          ? LoginColors.lightGreen 
          : LoginColors.softGreen.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: TextFormField(
      controller: codeController,
      focusNode: codeFocusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      obscureText: obscureCode,
      style: const TextStyle(
        color: Colors.white, 
        fontSize: 18, // ✅ کاهش فونت
        letterSpacing: 4, // ✅ کاهش letter spacing
        fontWeight: FontWeight.bold
      ),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(
          Icons.lock_outline, 
          color: codeFocusNode.hasFocus 
            ? LoginColors.lightGreen 
            : Colors.white70,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureCode ? Icons.visibility : Icons.visibility_off, 
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => setObscureCode(!obscureCode),
        ),
        hintText: '------',
        hintStyle: TextStyle(
          color: Colors.white30, 
          fontSize: 18, // ✅ کاهش فونت
          letterSpacing: 4
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validateVerificationCode,
      onChanged: (value) {
        // اتو تایید وقتی 6 رقم وارد شد
        if (value.length == 6 && !isLoading) {
          FocusScope.of(codeFocusNode.context!).unfocus();
          Future.delayed(const Duration(milliseconds: 300), () {
            onVerifyCode();
          });
        }
      },
    ),
  );

  Widget _buildResendButton() => TextButton.icon(
    onPressed: canResendCode && !isLoading ? resendCode : null,
    icon: Icon(
      Icons.refresh_rounded, 
      color: canResendCode && !isLoading ? LoginColors.lightGreen : Colors.white30, 
      size: 16 // ✅ کاهش سایز
    ),
    label: Text(
      canResendCode ? 'ارسال مجدد کد' : 'ارسال مجدد در $resendCooldown ثانیه',
      style: TextStyle(
        color: canResendCode && !isLoading ? LoginColors.lightGreen : Colors.white30, 
        fontSize: 13 // ✅ کاهش فونت
      ),
    ),
  );

  Widget _buildSubmitButton(VoidCallback onPressed, String text) => SizedBox(
    width: double.infinity,
    height: 48, // ✅ کاهش ارتفاع
    child: ElevatedButton(
      onPressed: isLoading ? null : () {
        debugPrint('🔥 دکمه $text فشرده شد - Loading: $isLoading');
        if (!isLoading) {
          onPressed();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        shadowColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading 
              ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)]
              : [LoginColors.primaryGreen, LoginColors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isLoading 
                ? Colors.grey.withOpacity(0.2)
                : LoginColors.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          child: isLoading
              ? LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 18) // ✅ کاهش سایز
              : Text(
                  text, 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold) // ✅ کاهش فونت
                ),
        ),
      ),
    ),
  );
}

class LoadingOverlay extends StatelessWidget {
  final Color primaryColor;
  const LoadingOverlay({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: LoadingAnimationWidget.staggeredDotsWave(color: primaryColor, size: 40),
    );
  }
}