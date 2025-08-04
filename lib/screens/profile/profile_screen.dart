// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/avatar_manager.dart';
import '../../utils/snackbar.dart';
import 'profile_avatar.dart';
import 'profile_payment.dart';
import 'profile_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late AvatarManager avatarManager;
  Map<String, dynamic> profile = {};
  double walletAmount = 0.0;
  bool isLoading = true;
  bool isEditing = false;
  bool isAvatarLoading = true;
  Map<String, dynamic> errors = {};
  String? paymentUrl;
  final ValueNotifier<int?> selectedAmount = ValueNotifier<int?>(null);
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool isWalletRefreshActive = false;

  // رنگ‌های سبز مطابق با ویزیت پیج
  final _primaryColor = const Color(0xFF2E7D66);     // سبز دریایی
  final _lightGreen = const Color(0xFF4CAF50);       // سبز روشن
  final _darkGreen = const Color(0xFF1B5E20);        // سبز تیره
  final _paleGreen = const Color(0xFFE8F7E8);        // سبز کم‌رنگ
  final _softGreen = const Color(0xFF66BB6A);        // سبز ملایم
  final _backgroundGreen = const Color(0xFFF1F8E9);  // پس‌زمینه سبز روشن

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await _initAvatarManager();
    await _loadProfileData();
  }

  Future<void> _initAvatarManager() async {
    final prefs = await SharedPreferences.getInstance();
    avatarManager = AvatarManager(prefs);
    setState(() => isAvatarLoading = false);
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    
    try {
      final result = await ProfileService.fetchProfileAndWallet();
      
      if (result['success']) {
        setState(() {
          profile = result['profile'];
          walletAmount = result['walletAmount'];
          _usernameController.text = profile['username'] ?? '';
          _emailController.text = profile['email'] ?? '';
          errors = {};
        });
        
        await _updateAvatarIfNeeded();
      } else {
        CustomSnackBar.show(result['error'], context, isError: true);
      }
    } catch (e) {
      CustomSnackBar.show('خطا در بارگذاری اطلاعات', context, isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAvatarIfNeeded() async {
    final username = profile['username'] ?? '';
    if (username.isNotEmpty && !avatarManager.isCurrentAvatarForUsername(username)) {
      await avatarManager.generateAvatarFromUsername(username);
      setState(() {});
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await ProfileService.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
      );

      if (result['success']) {
        setState(() {
          profile = result['profile'];
          isEditing = false;
          errors = {};
        });
        
        final newUsername = profile['username'] ?? '';
        if (newUsername.isNotEmpty) {
          await avatarManager.generateAvatarFromUsername(newUsername);
          setState(() {});
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('پروفایل و آواتار با موفقیت به‌روزرسانی شدند!'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        if (result['errors'] != null) {
          setState(() => errors = result['errors']);
        } else {
          CustomSnackBar.show(result['error'], context, isError: true);
        }
      }
    } catch (e) {
      CustomSnackBar.show('خطا در به‌روزرسانی پروفایل', context, isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _getPaymentLink() async {
    if (selectedAmount.value == null || selectedAmount.value! <= 0) {
      CustomSnackBar.show('لطفا مبلغ معتبری را انتخاب کنید', context, isError: true);
      return null;
    }

    setState(() => isLoading = true);
    
    try {
      final result = await ProfileService.createPaymentLink(selectedAmount.value!);
      
      if (result['success']) {
        setState(() => paymentUrl = result['paymentUrl']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لینک پرداخت با موفقیت ایجاد شد'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return result['paymentUrl'];
      } else {
        CustomSnackBar.show(result['error'], context, isError: true);
        return null;
      }
    } catch (e) {
      CustomSnackBar.show('خطا در ایجاد لینک پرداخت', context, isError: true);
      return null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _launchPaymentUrl() async {
    if (paymentUrl == null) return;
    
    final success = await ProfileService.launchPaymentUrl(paymentUrl!);
    if (success) {
      setState(() => isWalletRefreshActive = true);
    } else {
      CustomSnackBar.show('خطا در باز کردن لینک پرداخت!', context, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGreen,
      appBar: AppBar(
        title: _buildCloudTitle(),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _backgroundGreen,
        iconTheme: IconThemeData(color: _darkGreen),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _primaryColor),
            tooltip: 'آواتار تصادفی',
            onPressed: () async {
              await avatarManager.generateRandomAvatar();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('آواتار تصادفی جدید تولید شد!'),
                  backgroundColor: _primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading || isAvatarLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : _buildProfileView(),
    );
  }

  // ویجت عنوان ابری
  Widget _buildCloudTitle() {
    return CustomPaint(
      painter: CloudPainter(_primaryColor, _lightGreen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'پروفایل کاربری',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 19,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildWalletCard(),
          const SizedBox(height: 20),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildPaymentCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileAvatar(
            avatarManager: avatarManager,
            profile: profile,
            onAvatarChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(
            profile['username'] ?? '',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile['email'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: _primaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _softGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // آیکون Refresh در چپ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.sync,
                color: isWalletRefreshActive ? Colors.red : Colors.white,
                size: 24,
              ),
              tooltip: isWalletRefreshActive
                  ? 'بروزرسانی موجودی'
                  : 'پس از پرداخت بروزرسانی کنید',
              onPressed: isWalletRefreshActive
                  ? () async {
                      setState(() => isLoading = true);
                      await _loadProfileData();
                      setState(() => isWalletRefreshActive = false);
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // متن موجودی
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'موجودی کیف پول',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${walletAmount.toStringAsFixed(0)} ﷼',
                  style: TextStyle(
                    fontSize: 20,
                    color: walletAmount < 300000 ? Colors.red.shade100 : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // آیکون کیف پول در راست
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _softGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'اطلاعات حساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isEditing ? _buildEditForm() : _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _paleGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lightGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: _primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نام کاربری',
                      style: TextStyle(
                        fontSize: 12,
                        color: _darkGreen.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['username'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: _darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _paleGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lightGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.email, color: _primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ایمیل',
                      style: TextStyle(
                        fontSize: 12,
                        color: _darkGreen.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['email'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: _darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'نام کاربری',
              labelStyle: TextStyle(color: _primaryColor.withOpacity(0.8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              errorText: errors['username'] != null ? errors['username'][0] : null,
              prefixIcon: Icon(Icons.person, color: _primaryColor),
              helperText: 'تغییر نام کاربری آواتار شما را به‌روزرسانی می‌کند',
              filled: true,
              fillColor: _paleGreen.withOpacity(0.3),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'لطفاً نام کاربری را وارد کنید' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'ایمیل',
              labelStyle: TextStyle(color: _primaryColor.withOpacity(0.8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              errorText: errors['email'] != null ? errors['email'][0] : null,
              prefixIcon: Icon(Icons.email, color: _primaryColor),
              filled: true,
              fillColor: _paleGreen.withOpacity(0.3),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'لطفاً ایمیل را وارد کنید';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'لطفاً یک ایمیل معتبر وارد کنید';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isEditing)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _updateProfile,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        if (isEditing) ...[
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              isEditing = false;
              errors = {};
            }),
            icon: const Icon(Icons.cancel),
            label: const Text('لغو'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
        if (!isEditing)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(Icons.edit),
              label: const Text('ویرایش پروفایل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _softGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payment, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'شارژ کیف پول',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfilePayment(
              isLoading: isLoading,
              paymentUrl: paymentUrl,
              selectedAmount: selectedAmount,
              onGetPaymentLink: _getPaymentLink,
              onLaunchPaymentUrl: _launchPaymentUrl,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    selectedAmount.dispose();
    super.dispose();
  }
}

// CloudPainter برای ایجاد شکل ابر
class CloudPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CloudPainter(this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // شکل ابر با منحنی‌های نرم
    path.moveTo(size.width * 0.25, size.height * 0.65);
    
    // دایره کوچک چپ
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.25, size.height * 0.6),
      radius: size.height * 0.25,
    ));
    
    // دایره بزرگ وسط
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.45),
      radius: size.height * 0.35,
    ));
    
    // دایره متوسط راست
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.75, size.height * 0.55),
      radius: size.height * 0.3,
    ));
    
    // دایره کوچک راست
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.85, size.height * 0.7),
      radius: size.height * 0.2,
    ));

    // کف ابر
    path.addRect(Rect.fromLTWH(
      size.width * 0.15, 
      size.height * 0.75, 
      size.width * 0.7, 
      size.height * 0.25
    ));

    canvas.drawPath(path, paint);

    // افکت سایه داخلی
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2);
    
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}