import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../app_strings.dart';

class TeamCreateScreen extends StatefulWidget {
  final String userId;

  const TeamCreateScreen({super.key, required this.userId});

  @override
  State<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends State<TeamCreateScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  Future<void> createTeam() async {
    try {
      setState(() {
        isLoading = true;
      });

      final name = nameController.text.trim();
      final description = descriptionController.text.trim();

      if (name.isEmpty) {
        throw Exception(AppStrings.get(context, "errorTeamNameEmpty"));
      }

      final joinCode = await generateUniqueJoinCode();

      final insertedTeam = await supabase
          .from('teams')
          .insert({
            'name': name,
            'description': description.isEmpty ? null : description,
            'created_by': supabase.auth.currentUser!.id,
            'join_code': joinCode,
          })
          .select()
          .single();

      final teamId = insertedTeam['id'];

      await supabase.from('team_members').insert({
        'team_id': teamId,
        'user_id': widget.realUserId,
        'role': 'owner',
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get(context, "errorOccurred") + e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> generateUniqueJoinCode() async {
    while (true) {
      final code = generateJoinCode();

      final existing = await supabase
          .from('teams')
          .select('id')
          .eq('join_code', code)
          .maybeSingle();

      if (existing == null) {
        return code;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1C74E9);
    const backgroundLight = Color(0xFFF6F7F8);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),

                /// 모달 핸들바
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 제목
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.get(context, "teamCreateTitle"),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                ),

                /// 관리자 안내
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.05),
                      border: Border.all(color: primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.get(context, "teamCreateAdminInfo"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 입력 폼
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(context, "teamName"),
                          prefixIcon: const Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(context, "teamDescription"),
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 생성 버튼
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : createTeam,
                      icon: const Icon(Icons.rocket_launch),
                      label: Text(
                        AppStrings.get(context, "teamCreateComplete"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
