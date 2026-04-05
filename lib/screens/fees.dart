import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teamSelection.dart';

class CameraScreen extends StatefulWidget {
  final String userId;

  const CameraScreen({super.key, required this.userId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;

  // ✅ 이미지 선택 + 업로드
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isLoading = true);

    try {
      // 🔥 bytes 읽기
      final Uint8List fileBytes = await pickedFile.readAsBytes();

      // 🔥 확장자 추출
      final extension = pickedFile.name.split('.').last;

      // 🔥 파일명 생성
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final path = 'user/${widget.realUserId}/$fileName';

      // 🔥 mimeType (웹 대응)
      final mimeType = pickedFile.mimeType ?? 'image/$extension';

      // 1️⃣ Storage 업로드
      await supabase.storage
          .from('images')
          .uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      // 2️⃣ URL 생성
      final imageUrl =
      supabase.storage.from('images').getPublicUrl(path);

      // 3️⃣ DB 저장 (🔥 확장 컬럼 반영)
      await supabase.from('user_images').insert({
        'user_id': widget.realUserId,
        'image_url': imageUrl,

        'file_name': fileName,
        'file_size': fileBytes.length,
        'mime_type': mimeType,

        'thumbnail_url': imageUrl,

        'status': 'active',
        'is_public': false,

        'title': null,
        'description': null,
        'tags': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업로드 완료')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1C74E9);
    const backgroundLight = Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, widget.realUserId),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: isLoading ? null : _pickAndUploadImage,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamSelectionScreen(userId: userId),
                ),
              );
            },
            child: const Icon(Icons.group, size: 26),
          ),
          const Icon(Icons.notifications_outlined),
        ],
      ),
    );
  }
}