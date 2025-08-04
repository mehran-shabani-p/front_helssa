// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- رنگ‌های سبز ---
class PrescriptionColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

class PreviousPrescriptionsPage extends StatefulWidget {
  const PreviousPrescriptionsPage({super.key});

  @override
  State<PreviousPrescriptionsPage> createState() =>
      _PreviousPrescriptionsPageState();
}

class _PreviousPrescriptionsPageState extends State<PreviousPrescriptionsPage>
    with TickerProviderStateMixin {
  /* ──────────────── Controllers ──────────────── */
  final _medicineNameController = TextEditingController();
  final _doseController         = TextEditingController();
  final _quantityController     = TextEditingController();

  /* ──────────────── State vars ──────────────── */
  String? _selectedFrequency;
  String? _selectedPerIntake;
  final List<Map<String, String>> _medicineList = [];
  int? _editingIndex;

  /* ──────────────── Animations ──────────────── */
  late final AnimationController _buttonCtl;
  late final AnimationController _listCtl;
  late final Animation<double>   _btnScale;
  late final Animation<double>   _fadeAnim;

  /* ──────────────── Scroll control ──────────────── */
  final ScrollController _scrollCtl = ScrollController();

  /* ──────────────── Look-ups ──────────────── */
  static const _frequencies = [
    'هر روز',
    'هر شب',
    'هر 6 ساعت',
    'هر 8 ساعت',
    'هر 12 ساعت',
    'یک روز در میان',
    'دو بار در روز',
    'هفتگی',
    'در صورت نیاز',
    'سایر',
  ];
  static const _perIntakes = [
    'یک عدد',
    'دو عدد',
    'سه عدد',
    'چهار عدد',
    'نصف',
    'یک چهارم',
    'یک قطره',
    'دو قطره',
    'سه قطره',
    'طبق دستور',
  ];

  /* ──────────────── Lifecycle ──────────────── */
  @override
  void initState() {
    super.initState();
    _buttonCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _listCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _btnScale = Tween(begin: 1.0, end: .95).animate(
      CurvedAnimation(parent: _buttonCtl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listCtl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    _buttonCtl.dispose();
    _listCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  /* ──────────────── Helpers ──────────────── */
  bool _isValidPositiveNumber(String s) =>
      RegExp(r'^\d+(\.\d+)?$').hasMatch(s.trim()) && double.parse(s) > 0;

  void _showSnack(String msg, Color bg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
    );
  }

  void _error(String msg) =>
      _showSnack(msg, Colors.red, Icons.error_outline);
  void _success(String msg) =>
      _showSnack(msg, PrescriptionColors.lightGreen, Icons.check_circle_outline);

  /* ──────────────── Add / Update ──────────────── */
  Future<void> _addOrUpdateMedicine() async {
    final name  = _medicineNameController.text.trim();
    final dose  = _doseController.text.trim();
    final qty   = _quantityController.text.trim();

    if (name.isEmpty) {
      _error('نام دارو الزامی است');
      return;
    }
    if (!_isValidPositiveNumber(dose)) {
      _error('دوز دارو باید عددی معتبر باشد');
      return;
    }

    final isEdit = _editingIndex != null;

    await _buttonCtl.forward();
    if (!mounted) return;
    await _buttonCtl.reverse();
    if (!mounted) return;

    final med = {
      'name'     : name,
      'doseMg'   : dose,
      'perIntake': _selectedPerIntake ?? '',
      'frequency': _selectedFrequency ?? '',
      'quantity' : qty,
    };

    setState(() {
      if (isEdit) {
        _medicineList[_editingIndex!] = med;
        _editingIndex = null;
      } else {
        _medicineList.add(med);
        _listCtl.forward(from: 0);
      }
      if (_medicineList.isEmpty) _listCtl.reset();
    });

    _clearForm();
    _success(isEdit ? 'دارو ویرایش شد' : 'دارو اضافه شد');
  }

  /* ──────────────── Edit ──────────────── */
  void _editMedicine(int index) {
    final m = _medicineList[index];
    setState(() {
      _editingIndex        = index;
      _medicineNameController.text = m['name']!;
      _doseController.text        = m['doseMg']!;
      _selectedPerIntake          = m['perIntake']!.isEmpty ? null : m['perIntake'];
      _selectedFrequency          = m['frequency']!.isEmpty ? null : m['frequency'];
      _quantityController.text    = m['quantity']!;
    });

    _scrollCtl.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /* ──────────────── Remove ──────────────── */
  void _removeMedicine(int idx) {
    setState(() {
      _medicineList.removeAt(idx);
      if (_editingIndex == idx) {
        _clearForm();
        _editingIndex = null;
      }
      if (_medicineList.isEmpty) _listCtl.reset();
    });
    _success('دارو حذف شد');
  }

  /* ──────────────── Clear Form ──────────────── */
  void _clearForm() {
    _medicineNameController.clear();
    _doseController.clear();
    _quantityController.clear();
    setState(() {
      _selectedFrequency = null;
      _selectedPerIntake = null;
      _editingIndex      = null;
    });
  }

  /* ──────────────── Final Submit ──────────────── */
  Future<void> _finalSubmit() async {
    if (_medicineList.isEmpty) {
      _error('حداقل یک دارو اضافه کنید');
      return;
    }

    await _buttonCtl.forward();
    if (!mounted) return;
    await _buttonCtl.reverse();
    if (!mounted) return;

    final text = _medicineList.map((m) {
      final title = '${m['name']} ${m['doseMg']}';
      final parts = <String>[title];
      if (m['perIntake']!.isNotEmpty) parts.add('💊 ${m['perIntake']}');
      if (m['frequency']!.isNotEmpty) parts.add('⏰ ${m['frequency']}');
      if (m['quantity']!.isNotEmpty) parts.add('📦 ${m['quantity']}');
      return parts.join(' - ');
    }).join('\n');

    Navigator.of(context).pop(text);
  }

  /* ──────────────── UI ──────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrescriptionColors.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'ثبت داروهای روتین',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: PrescriptionColors.primaryGreen,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          if (_medicineList.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: _finalSubmit,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('ثبت نهایی'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PrescriptionColors.lightGreen, 
                  PrescriptionColors.softGreen, 
                  PrescriptionColors.primaryGreen
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  _buildAddMedicineCard(),
                  if (_medicineList.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildMedicineList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ──────────────── Add Medicine Card ──────────────── */
  Widget _buildAddMedicineCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(),
            const SizedBox(height: 24),
            _modernField(
              controller: _medicineNameController,
              label: 'نام دارو',
              icon: Icons.medication_liquid_rounded,
              gradient: _green,
              required: true,
            ),
            const SizedBox(height: 20),
            _modernField(
              controller: _doseController,
              label: 'دوز دارو',
              icon: Icons.local_pharmacy_rounded,
              gradient: _darkGreen,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,1})?')),
              ],
              suffix: const Text('mg'),
            ),
            const SizedBox(height: 20),
            _modernField(
              controller: _quantityController,
              label: 'تعداد',
              icon: Icons.numbers_rounded,
              gradient: _lightGreen,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _modernDropdown(
                    value: _selectedPerIntake,
                    label: 'مقدار مصرف',
                    icon: Icons.medical_services_rounded,
                    items: _perIntakes,
                    onChanged: (v) => setState(() => _selectedPerIntake = v),
                    gradient: _softGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _modernDropdown(
                    value: _selectedFrequency,
                    label: 'زمان مصرف',
                    icon: Icons.schedule_rounded,
                    items: _frequencies,
                    onChanged: (v) => setState(() => _selectedFrequency = v),
                    gradient: _primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_editingIndex != null) ...[
                  Expanded(
                    child: _modernButton(
                      onPressed: _clearForm,
                      icon: Icons.clear_rounded,
                      label: 'لغو',
                      gradient: _grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ScaleTransition(
                    scale: _btnScale,
                    child: _modernButton(
                      onPressed: _addOrUpdateMedicine,
                      icon: _editingIndex != null ? Icons.edit_rounded : Icons.add,
                      label: _editingIndex != null ? 'ویرایش' : 'افزودن',
                      gradient: _green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ──────────────── Medicine List ──────────────── */
  Widget _buildMedicineList() {
    return Container(
      decoration: _cardDecoration(shadowColor: PrescriptionColors.primaryGreen.withOpacity(.1)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _primaryGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'لیست داروها',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _counterChip(_medicineList.length),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _medicineList.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (_, idx) => AnimatedContainer(
              key: ValueKey('${_medicineList[idx]['name']}-$idx'),
              duration: Duration(milliseconds: 300 + idx * 80),
              curve: Curves.easeOutBack,
              child: _medicineTile(idx),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _medicineTile(int idx) {
    final m = _medicineList[idx];
    String v(String? s) => (s?.trim().isNotEmpty ?? false) ? s!.trim() : '--';

    final details = [
      '💊 ${v(m['perIntake'])}',
      '⏰ ${v(m['frequency'])}',
      '📦 ${v(m['quantity'])}',
    ];

    return ListTile(
      leading: _iconCircle(),
      title: Text(
        '${m['name']} ${m['doseMg']} mg',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: PrescriptionColors.darkGreen,
        ),
      ),
      subtitle: Text(
        details.join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13, 
          color: Colors.grey[600], 
          height: 1.3,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionBtn(
            onTap: () => _editMedicine(idx),
            icon: Icons.edit_rounded,
            gradient: _lightGreen,
          ),
          const SizedBox(width: 8),
          _actionBtn(
            onTap: () => _removeMedicine(idx),
            icon: Icons.close_rounded,
            gradient: _red,
          ),
        ],
      ),
    );
  }

  /* ──────────────── Widgets (atoms) ──────────────── */
  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Gradient gradient,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return Container(
      decoration: _fieldShadow(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          suffix: suffix,
          prefixIcon: _prefix(icon, gradient),
          filled: true,
          fillColor: Colors.white,
          border: _border,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: PrescriptionColors.primaryGreen.withOpacity(0.7), 
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _modernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Gradient gradient,
  }) {
    return Container(
      decoration: _fieldShadow(),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: _prefix(icon, gradient),
          filled: true,
          fillColor: Colors.white,
          border: _border,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: PrescriptionColors.primaryGreen.withOpacity(0.7), 
            fontWeight: FontWeight.w500,
          ),
        ),
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: PrescriptionColors.primaryGreen),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _modernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      decoration: _btnShadow(gradient),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required VoidCallback onTap,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: _btnShadow(gradient, radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _counterChip(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$n',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _iconCircle() => Container(
        width: 50,
        height: 50,
        decoration: _btnShadow(_green, radius: 25),
        child: const Icon(Icons.medication_liquid_rounded, color: Colors.white),
      );

  Widget _prefix(IconData i, Gradient g) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: g, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(i, color: Colors.white, size: 20),
      );

  BoxDecoration _cardDecoration({Color? shadowColor}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PrescriptionColors.lightGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? PrescriptionColors.primaryGreen.withOpacity(.1),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      );

  BoxDecoration _fieldShadow() => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PrescriptionColors.primaryGreen.withOpacity(.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      );

  BoxDecoration _btnShadow(Gradient g, {double radius = 16}) => BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: g.colors.first.withOpacity(.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      );

  InputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: BorderSide.none,
      );

  Widget _cardHeader() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _btnShadow(_green, radius: 16),
            child: const Icon(Icons.medication_liquid_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            _editingIndex != null ? 'ویرایش دارو' : 'افزودن دارو جدید',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PrescriptionColors.darkGreen,
            ),
          ),
        ],
      );

  /* ──────────────── Color helpers ──────────────── */
  static const _green = LinearGradient(
    colors: [PrescriptionColors.lightGreen, PrescriptionColors.primaryGreen],
  );
  static const _primaryGreen = LinearGradient(
    colors: [PrescriptionColors.primaryGreen, PrescriptionColors.darkGreen],
  );
  static const _lightGreen = LinearGradient(
    colors: [PrescriptionColors.softGreen, PrescriptionColors.lightGreen],
  );
  static const _darkGreen = LinearGradient(
    colors: [PrescriptionColors.darkGreen, PrescriptionColors.primaryGreen],
  );
  static const _softGreen = LinearGradient(
    colors: [PrescriptionColors.paleGreen, PrescriptionColors.softGreen],
  );
  static const _red = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
  );
  static const _grey = LinearGradient(
    colors: [Color(0xFF95A5A6), Color(0xFF7F8C8D)],
  );
}