import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

  class ProfilePaymentColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}
class ProfilePayment extends StatefulWidget {
  final bool isLoading;
  final String? paymentUrl;
  final ValueNotifier<int?> selectedAmount;
  final Future<String?> Function() onGetPaymentLink;
  final VoidCallback onLaunchPaymentUrl;



  const ProfilePayment({
    super.key,
    required this.isLoading,
    required this.paymentUrl,
    required this.selectedAmount,
    required this.onGetPaymentLink,
    required this.onLaunchPaymentUrl,
  });

  @override
  State<ProfilePayment> createState() => _ProfilePaymentState();
}

class _ProfilePaymentState extends State<ProfilePayment> {
  late TextEditingController customAmountController;
  String? localPaymentUrl; // UPDATED: Local state to track payment URL

  @override
  void initState() {
    super.initState();
    customAmountController = TextEditingController();
    localPaymentUrl = widget.paymentUrl;
  }

  @override
  void didUpdateWidget(ProfilePayment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentUrl != oldWidget.paymentUrl) {
      setState(() {
        localPaymentUrl = widget.paymentUrl;
      });
    }
  }

  String _formatNumber(int number) => NumberFormat('#,###').format(number);

  void _onChipSelected(int amount) {
    widget.selectedAmount.value = amount;
    customAmountController.clear();
    setState(() => localPaymentUrl = null); // UPDATED: Reset payment URL
  }

  void _onCustomAmountChanged(String value) {
    final amount = int.tryParse(value.replaceAll(',', ''));
    widget.selectedAmount.value = amount;
    setState(() => localPaymentUrl = null); // UPDATED: Reset payment URL
  }

  Widget _buildVisitChip(int visitCount, int amount) {
    // UPDATED: Define colors for the chip
    
    return ChoiceChip(
      label: Text('ویزیت $visitCount'),
      selected: widget.selectedAmount.value == amount,
      onSelected: (selected) => _onChipSelected(selected ? amount : 0),
      backgroundColor: ProfilePaymentColors.primaryGreen,
      selectedColor: ProfilePaymentColors.lightGreen,
      labelStyle: TextStyle(
        color: widget.selectedAmount.value == amount ? ProfilePaymentColors.paleGreen : ProfilePaymentColors.darkGreen,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfilePaymentColors.backgroundGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color.fromARGB(131, 12, 91, 12).withOpacity(0.8),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'پرداخت ویزیت',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'قیمت ویزیت: 29,990 تومان',
            style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildVisitChip(1, 300000),
              _buildVisitChip(2, 600000),
              _buildVisitChip(3, 900000),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: customAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'مبلغ دلخواه (ریال)',
              hintText: 'مبلغ بین 100,000 تا 5,000,000 ریال',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.monetization_on),
            ),
            onChanged: _onCustomAmountChanged,
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<int?>(
            valueListenable: widget.selectedAmount,
            builder: (context, amount, _) => Text(
              amount != null
                  ? 'مبلغ انتخاب شده: ${_formatNumber(amount)} ریال'
                  : 'لطفاً تعداد ویزیت یا مبلغ را انتخاب کنید',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ElevatedButton.icon(
  onPressed: widget.isLoading || widget.selectedAmount.value == null
      ? null
      : (localPaymentUrl != null
          ? widget.onLaunchPaymentUrl
          : () async {
              setState(() => widget.isLoading);
              final url = await widget.onGetPaymentLink();
              if (url != null) {
                setState(() => localPaymentUrl = url);
              }
            }),
            icon: Icon(localPaymentUrl != null ? Icons.payment : Icons.link),
            label: Text(localPaymentUrl != null ? 'ادامه به پرداخت' : 'دریافت لینک پرداخت'),
            style: ElevatedButton.styleFrom(
              padding       : const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: localPaymentUrl != null
              ? ProfilePaymentColors.darkGreen       // بعد از دریافت لینک
              : ProfilePaymentColors.softGreen,      // حالت اولیه (رنگ کم‌رنگ)
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تراکنش شما توسط سیستم امن ما محافظت می‌شود.',
            style: TextStyle(fontSize: 12, color: ProfilePaymentColors.primaryGreen),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
