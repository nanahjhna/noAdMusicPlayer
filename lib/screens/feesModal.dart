import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_strings.dart'; // 추가

class FeesModal extends StatefulWidget {
  final String teamId;

  const FeesModal({super.key, required this.teamId});

  @override
  State<FeesModal> createState() => _FeesModalState();
}

class _FeesModalState extends State<FeesModal> {
  final supabase = Supabase.instance.client;

  bool isExpense = true;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4F46E5);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            /// ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get(context, 'add_entry'), // "내역 추가"
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            /// ===== Body =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 구분
                    Text(
                      AppStrings.get(context, 'type'), // "구분"
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeButton(AppStrings.get(context, 'expense'), true),
                        // "지출"
                        const SizedBox(width: 12),
                        _typeButton(AppStrings.get(context, 'income'), false),
                        // "수입"
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// 항목명
                    Text(
                      AppStrings.get(context, 'item_name'), // "항목명"
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _textField(
                      controller: nameController,
                      hint: AppStrings.get(
                        context,
                        'item_name_hint',
                      ), // "예: 사무용품 구매"
                    ),
                    const SizedBox(height: 20),

                    /// 금액
                    Text(
                      AppStrings.get(context, 'amount'), // "금액"
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _textField(
                      controller: amountController,
                      hint: "0",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    /// 날짜
                    Text(
                      AppStrings.get(context, 'date'), // "날짜"
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 비고
                    Text(
                      AppStrings.get(context, 'remarks'), // "비고"
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _textField(
                      controller: remarksController,
                      hint: AppStrings.get(context, 'remarks_hint'),
                      // "기타 참고사항"
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            /// ===== Footer =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppStrings.get(context, 'save')), // "저장하기"
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    if (amountController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('dues').insert({
        'team_id': widget.teamId,
        'user_id': user?.id,
        'type': isExpense ? 'expense' : 'income',
        'amount': double.parse(amountController.text),
        'description': nameController.text,
        'status': '미납',
        'due_date': DateFormat('yyyy-MM-dd').format(selectedDate),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Insert error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _typeButton(String text, bool expense) {
    final selected = isExpense == expense;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isExpense = expense),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}
