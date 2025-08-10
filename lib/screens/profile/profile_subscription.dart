// Create a new file: profile_subscription.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'profile_service.dart';

class ProfileSubscription extends StatefulWidget {
  final Function onRefresh;
  final bool isLoading;
  
  const ProfileSubscription({
    Key? key,
    required this.onRefresh,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<ProfileSubscription> createState() => _ProfileSubscriptionState();
}

class _ProfileSubscriptionState extends State<ProfileSubscription> {
  List<Map<String, dynamic>> plans = [];
  Map<String, dynamic>? currentSubscription;
  bool isLoadingPlans = true;
  bool isLoadingSub = true;
  String? errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadPlans(),
      _loadCurrentSubscription(),
    ]);
  }
  
  Future<void> _loadPlans() async {
    setState(() => isLoadingPlans = true);
    
    try {
      final result = await ProfileService.fetchSubscriptionPlans();
      
      if (result['success']) {
        setState(() {
          plans = List<Map<String, dynamic>>.from(result['plans']);
          errorMessage = null;
        });
      } else {
        setState(() => errorMessage = result['error']);
      }
    } catch (e) {
      setState(() => errorMessage = 'خطا در بارگذاری پلن‌ها: ${e.toString()}');
    } finally {
      setState(() => isLoadingPlans = false);
    }
  }
  
  Future<void> _loadCurrentSubscription() async {
    setState(() => isLoadingSub = true);
    
    try {
      final result = await ProfileService.fetchUserSubscription();
      
      if (result['success']) {
        setState(() {
          currentSubscription = result['subscription'];
          errorMessage = null;
        });
      } else {
        setState(() => errorMessage = result['error']);
      }
    } catch (e) {
      setState(() => errorMessage = 'خطا در بارگذاری اشتراک: ${e.toString()}');
    } finally {
      setState(() => isLoadingSub = false);
    }
  }
  
  Future<void> _buySubscription(int planId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید خرید اشتراک'),
        content: const Text('آیا از خرید این اشتراک اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() => isLoadingSub = true);
              
              try {
                final result = await ProfileService.buySubscription(planId);
                
                if (result['success']) {
                  setState(() {
                    currentSubscription = result['subscription'];
                    errorMessage = null;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('اشتراک با موفقیت خریداری شد!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  widget.onRefresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطا در خرید اشتراک: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => isLoadingSub = false);
              }
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isActive = currentSubscription != null && 
                          currentSubscription!['plan'] != null && 
                          currentSubscription!['plan']['id'] == plan['id'];
    
    final primaryColor = const Color(0xFF2E7D66);
    final darkGreen = const Color(0xFF1B5E20);
    final paleGreen = const Color(0xFFE8F7E8);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? darkGreen : Colors.grey.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [paleGreen, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? darkGreen : Colors.black87,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'فعال',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${plan['days']} روز',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${plan['price'].toString()} ﷼',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isActive)
              ElevatedButton(
                onPressed: widget.isLoading || isLoadingSub
                    ? null
                    : () => _buySubscription(plan['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('خرید اشتراک'),
              ),
            if (isActive && currentSubscription != null)
              Column(
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تاریخ شروع:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        _formatDate(currentSubscription!['start_date']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تاریخ پایان:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        _formatDate(currentSubscription!['end_date']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentSubscription != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D66).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D66).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: Color(0xFF2E7D66),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اشتراک فعال: ${currentSubscription!['plan']['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تا تاریخ ${_formatDate(currentSubscription!['end_date'])} معتبر است',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (isLoadingPlans || isLoadingSub)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (errorMessage != null)
          Center(
            child: Column(
              children: [
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          )
        else if (plans.isEmpty)
          const Center(
            child: Text('در حال حاضر هیچ پلن اشتراکی موجود نیست.'),
          )
        else
          Column(
            children: plans.map((plan) => _buildPlanCard(plan)).toList(),
          ),
      ],
    );
  }
}