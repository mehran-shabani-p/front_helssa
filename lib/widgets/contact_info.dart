// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'contact_service.dart';
import '../constants.dart';

/* ============================================================================
صفحهٔ ContactInfo بهبود یافته برای وب و موبایل با طراحی کامل
===========================================================================*/

class ContactInfo extends StatelessWidget {
  const ContactInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContactColors.backgroundGreen,
      appBar: _buildAppBar(context),
      drawer: kIsWeb ? null : _buildMobileDrawer(context), // فقط در موبایل
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive design برای وب
            if (kIsWeb && constraints.maxWidth > 768) {
              return _buildWebLayout(context);
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _buildShimmerTitle(),
      centerTitle: true,
      elevation: 0,
      backgroundColor: ContactColors.primaryGreen,
      foregroundColor: Colors.white,
      leading: kIsWeb 
          ? null // در وب drawer نداریم
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      actions: kIsWeb ? [
        // در وب، دکمه‌های اضافی در AppBar
        TextButton.icon(
          onPressed: () => ContactService.showTermsDialog(context),
          icon: const Icon(Icons.gavel_rounded, color: Colors.white),
          label: const Text('قوانین', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => ContactService.showHelpDialog(context),
          icon: const Icon(Icons.help_outline, color: Colors.white),
          label: const Text('راهنما', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 16),
      ] : null,
    );
  }

  // عنوان درخشان HELSSA
  Widget _buildShimmerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.white,
            ContactColors.paleGreen,
            Colors.white,
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: const Text(
        'HELSSA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar در وب
        Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ContactColors.primaryGreen, ContactColors.darkGreen],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildDrawerSectionsList(context), // ✅ تابع جداگانه
                  ),
                ),
              ),
              _buildVersionFooter(),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildContactGrid(), // Grid layout برای وب
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          _buildContactList(), // List layout برای موبایل
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.local_hospital_rounded,
              size: 40,
              color: ContactColors.primaryGreen,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'HELSSA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'سامانه سلامت',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ تابع جداگانه برای جلوگیری از تکرار
  List<Widget> _buildDrawerSectionsList(BuildContext context) {
    return ContactService.getDrawerSections(context)
        .map<Widget>((section) => _buildWebSidebarSection(section))
        .toList();
  }

  Widget _buildWebSidebarSection(Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            section['title'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ تبدیل items به List<Widget>
        ...section['items'].map<Widget>((item) => _buildSidebarItem(
          icon: item['icon'],
          title: item['title'],
          subtitle: item['subtitle'],
          onTap: item['onTap'],
        )).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              )
            : null,
        onTap: () {
          debugPrint('🔥 Sidebar item clicked: $title'); // ✅ Debug
          onTap();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            'نسخه ${currentVersion}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ContactColors.primaryGreen, ContactColors.softGreen],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          children: [
            Icon(
              Icons.contact_support_rounded,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'ارتباط با ما',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ما همیشه در خدمت شما هستیم',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: ContactService.contactMethods
            .where((contact) => kIsWeb ? contact['isExternal'] : true) // فیلتر برای وب
            .map((contact) => _ContactCard(
                  icon: _getIconData(contact['icon']),
                  title: contact['title'],
                  subtitle: contact['subtitle'],
                  content: contact['content'],
                  url: contact['url'],
                  color: contact['color'],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContactGrid() {
    final filteredContacts = ContactService.contactMethods
        .where((contact) => contact['isExternal']) // فقط لینک‌های خارجی در وب
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return _ContactCard(
          icon: _getIconData(contact['icon']),
          title: contact['title'],
          subtitle: contact['subtitle'],
          content: contact['content'],
          url: contact['url'],
          color: contact['color'],
          isWebCard: true,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ContactColors.lightGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ContactColors.primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ContactColors.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              color: ContactColors.primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'سلامتی شما، اولویت ماست',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ContactColors.darkGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'با تیم پزشکی متخصص ما در ارتباط باشید و از خدمات تله‌مدیسین پیشرفته بهره‌مند شوید',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: ContactColors.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                'امن و مطمئن',
                style: TextStyle(
                  color: ContactColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.access_time, color: ContactColors.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                '۲۴/۷ در دسترس',
                style: TextStyle(
                  color: ContactColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ContactColors.primaryGreen, ContactColors.darkGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 40,
                      color: ContactColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'HELSSA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // ✅ استفاده از تابع جداگانه
            ..._buildDrawerSectionsList(context),
            _buildVersionFooter(),
          ],
        ),
      ),
    );
  }

  // ✅ تابع جداگانه برای drawer sections  



  IconData _getIconData(dynamic iconRef) {
    if (iconRef is IconData) return iconRef;
    
    // Map string names to icons
    switch (iconRef.toString()) {
      case 'fontawesome.instagram':
        return FontAwesomeIcons.instagram;
      case 'fontawesome.telegram':
        return FontAwesomeIcons.telegram;
      case 'fontawesome.whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'fontawesome.paperPlane':
        return FontAwesomeIcons.paperPlane;
      case 'material.email_rounded':
        return Icons.email_rounded;
      case 'material.sms_rounded':
        return Icons.sms_rounded;
      default:
        return Icons.contact_support;
    }
  }
}

/* ============================================================================
ویجت _ContactCard بهبود یافته با تم سبز برای وب و موبایل
===========================================================================*/

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String content;
  final String url;
  final Color color;
  final bool isWebCard;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.url,
    required this.color,
    this.isWebCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isWebCard ? 0 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleTap(context),
          onHover: kIsWeb ? (hovering) {
            // Hover effect برای وب
          } : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isWebCard ? _buildWebCardContent() : _buildMobileCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildWebCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ContactColors.darkGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCardContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ContactColors.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    debugPrint('🔥 Contact card clicked: $title'); // ✅ Debug
    final success = await ContactService.launchContactUrl(url);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('خطا در باز کردن لینک'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (kIsWeb) {
      ContactService.showSuccessSnackBar(context, 'لینک در تب جدید باز شد');
    }
  }
}