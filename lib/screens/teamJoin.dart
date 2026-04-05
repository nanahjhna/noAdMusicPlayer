import 'package:flutter/material.dart';
import '../app_strings.dart'; // AppStrings 파일 import

class TeamJoinScreen extends StatelessWidget {
  const TeamJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1C74E9);
    const backgroundLight = Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.get(context, "teamJoinTitle"), // 팀 참가
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 2 / 3,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Text(
                    AppStrings.get(context, "teamJoinEnterCodeTitle"),
                    // 팀 코드를 입력하세요
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111418),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get(context, "teamJoinEnterCodeSubtitle"),
                    // 팀장이 공유한 6자리 코드를 입력하여 워크스페이스에 참여하세요.
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF637388),
                    ),
                  ),
                ],
              ),
            ),

            // Entry Code Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  bool filled = index < 3; // 예시 입력값
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: filled ? primary : const Color(0xFFDCE0E5),
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                          hintText: filled ? null : '•',
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Team Preview Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Team Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primary.withOpacity(0.1),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuCAVhB4WceY4OAW02b5l85kg8cHzW1VS23EKFLo3HBgfrmDK59FTMI3Hg2ERQdrYkn09lfXOUUM6lBruv3sMius6B0VDL7Hd2j8loIzZr_eF7ADwC3yN9wvwe6zHvGe7tLcvCGWE0bKRV3VbhnwnjmWHQ4XX0ge11_P4qQKrZtM57__sSZDD2l-Nyj2sZxDpj5a57dKvViXUsAIjncBr3dpWHbqGYaSUvUMfWZvOK_jbBbJ64y1YHXjaWyithGIZJcvTavcFSzJhw",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Team Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: primary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.get(context, "teamVerified"),
                                // 인증된 팀
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.get(context, "teamNamePreview"),
                            // 팀 확인됨: noAdMusicPlayer Design
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(
                                      "https://lh3.googleusercontent.com/aida-public/AB6AXuCdbS4YGSsfyt4Degp9OcFeOY7b-HqVIc4ip9K_YEqrqqfn8IcggKufI_Xs9ha1JaM5aT1adV4kvATJGXqLSW4OTX9nCLg9cDSv_dqy8MJW99KiHn85pmuoU57VZXHKEcw1RsIEMOFPv0mZTuM38zcTznfNuWRrIBKovWo22-QCBJvA7WenNvgCNN6tTJeUwKy1mlEiHw7METK04bLbjTgfl_juMb5mUDCvcdDMnSItD7dtxWSQQkhwT72-jDWuM4V3Fj7bKWkmyQ",
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundImage: NetworkImage(
                                        "https://lh3.googleusercontent.com/aida-public/AB6AXuALWjptfjIjySM2ZhhFwiKK5_-_vc9Ww4hERR7ypujHeB-utDZGqvP4cBSOwBYjZnpeBSRsAlC-U6eTAxufQKIN99ta60yuRacWzG6PyUzekEK16yfg3XuW8Rb7ceM9H4_FLhEnq6xz4WImxdqQeHOr7ugYy7I20M5D2zB4rsRP8Hah5k6CdUx20qSc6TOQyY84kXsUU9Qn0DsBrdOKfXDFcmZ8yXLeT6QQIeJVdZyDJC01SdMjFCyRz1CxFNiBJkU2Sn4c1yPWYg",
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 32,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+4',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.get(context, "teamActiveMembers"),
                                // 6명 활동 중
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF637388),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        AppStrings.get(context, "joinComplete"), // 참가 완료
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.get(context, "cancel"), // Cancel
                        style: const TextStyle(color: Color(0xFF637388)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
