import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_strings.dart';

class MemberModal extends StatefulWidget {
  final String memberId; // team_members.id
  final String role; // 현재 role 값

  const MemberModal({super.key, required this.memberId, required this.role});

  @override
  State<MemberModal> createState() => _MemberModalState();
}

class _MemberModalState extends State<MemberModal> {
  final supabase = Supabase.instance.client;

  late String selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.role;
  }

  /// 🔹 role 수정
  Future<void> _updateMember() async {
    try {
      await supabase
          .from('team_members')
          .update({
            'role': selectedRole,
            'update_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.memberId);

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("수정 오류: $e");
    }
  }

  /// 🔹 삭제
  Future<void> _deleteMember() async {
    try {
      await supabase.from('team_members').delete().eq('id', widget.memberId);

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("삭제 오류: $e");
    }
  }

  /// 🔹 팀 멤버 탈퇴 처리
  Future<void> _leaveMember() async {
    try {
      await supabase
          .from('team_members')
          .update({'role': 'leave'}) // role을 'leave'로 변경
          .eq('id', widget.memberId);

      Navigator.pop(context, true); // 완료 후 이전 화면으로
    } catch (e) {
      debugPrint("탈퇴 처리 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1C74E9);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.6,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                AppStrings.get(context, "updateRole"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  _roleButton(AppStrings.get(context, "admin"), "admin"),
                  const SizedBox(width: 10),
                  _roleButton(AppStrings.get(context, "member"), "member"),
                ],
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.get(context, "cancel")),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: _updateMember,
                      child: Text(AppStrings.get(context, "update")),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: _leaveMember,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  AppStrings.get(context, "deleteMember"),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 role 선택 버튼
  Widget _roleButton(String text, String value) {
    const primary = Color(0xFF1C74E9);
    final selected = selectedRole == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
