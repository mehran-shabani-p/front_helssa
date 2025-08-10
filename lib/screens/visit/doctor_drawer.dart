import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Drawer widget that slides from the top‑right showing the on‑call doctor's info.
/// همچنین وضعیت موجودی کیف‌پول کاربر را (کافی/ناکافی) نمایش می‌دهد.
class DoctorDrawer extends StatefulWidget {
  final String? name, specialty, imageUrl, message;
  final Color accent, paleBlue;

  const DoctorDrawer({
    super.key,
    required this.accent,
    required this.paleBlue,
    this.name,
    this.specialty,
    this.imageUrl,
    this.message,
  });

  @override
  State<DoctorDrawer> createState() => _DoctorDrawerState();
}

class _DoctorDrawerState extends State<DoctorDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  int? _remain; // موجودی پس از کسر هزینه
  bool _loadingBalance = true;
  static const _visitCost = 300000; //  (۳۰۰,۰۰۰ ریال = ۳۰,۰۰۰ تومان)

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

Future<void> _fetchBalance() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    if (token.isEmpty) throw Exception('no token');

    final res = await http.post(
      Uri.parse('https://api.medogram.ir/api/box/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 6));

    if (res.statusCode == 200) {
      final data    = jsonDecode(res.body) as Map;
      final balance = (data['amount'] as num).round();
      if (!mounted) return;
      setState(() {
        _remain          = balance - _visitCost;
        _loadingBalance  = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _remain         = null;
        _loadingBalance = false;
      });
    }
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _remain         = null;
      _loadingBalance = false;
    });
  }
}

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String statusText;
    Color statusColor = widget.accent;
    IconData? statusIcon;

    if (_loadingBalance) {
      statusText = '…';
    } else if (_remain == null) {
      statusText = '--';
      statusIcon = Icons.help_outline;
      statusColor = Colors.grey;
    } else if (_remain! >= 0) {
      statusText = 'کافی';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else {
      statusText = 'ناکافی';
      statusIcon = Icons.cancel;
      statusColor = Colors.red;
    }

    final balanceRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('موجودی: ', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
        if (!_loadingBalance) ...[
          const SizedBox(width: 4),
          Icon(statusIcon, size: 18, color: statusColor),
        ],
      ],
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, -1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: widget.message != null
              ? Text(widget.message!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _doctorAvatar(),
                    const SizedBox(height: 12),
                    Text(widget.name ?? '', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: widget.accent)),
                    const SizedBox(height: 4),
                    Text(widget.specialty ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    const SizedBox(height: 8),
                    balanceRow,
                  ],
                ),
        ),
      ),
    );
  }

  /// تصویر پزشک با هندل خطا برای جلوگیری از استثنای «EncodingError»
  Widget _doctorAvatar() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return CircleAvatar(radius: 32, backgroundColor: widget.paleBlue, child: Icon(Icons.person, size: 36, color: widget.accent));
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: widget.paleBlue,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (_, _) => Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent))),
          errorWidget: (_, _, _) => Icon(Icons.person, size: 36, color: widget.accent),
        ),
      ),
    );
  }

  // عدد سه‌رقمی‌شده (فعلاً نگه‌داری‌شده برای استفادهٔ احتمالی آینده)
}
