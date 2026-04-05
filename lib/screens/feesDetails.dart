import 'package:flutter/material.dart';
import '../app_strings.dart';

class FeesDetailsScreen extends StatelessWidget {
  const FeesDetailsScreen({super.key});

  static const primary = Color(0xFF1C74E9);

  @override
  Widget build(BuildContext context) {
    const backgroundLight = Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                /// HEADER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.account_balance_wallet,
                            color: primary,
                            size: 32,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "noAdMusicPlayer",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.2),
                              border: Border.all(
                                color: primary.withOpacity(0.3),
                              ),
                            ),
                            child: const ClipOval(child: Icon(Icons.person)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// MONTH SELECT
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, color: primary),
                                    SizedBox(width: 8),
                                    Text(
                                      "2023년 10월",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.expand_more),
                              ],
                            ),
                          ),
                        ),

                        /// SUMMARY
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryCard(
                                context,
                                icon: Icons.trending_up,
                                iconColor: Colors.green,
                                title: "수입",
                                amount: "5240",
                                change: "+12.5%",
                                primaryColor: Colors.green,
                              ),
                              _summaryCard(
                                context,
                                icon: Icons.trending_down,
                                iconColor: Colors.red,
                                title: "지출",
                                amount: "3120",
                                change: "-4.2%",
                                primaryColor: Colors.red,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// TRANSACTION LIST
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "최근 내역",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),

                              _transactionItem(
                                context,
                                icon: Icons.shopping_bag,
                                iconBgColor: Colors.grey.shade200,
                                title: "사무용품",
                                date: "Oct 12",
                                amount: "45",
                                manager: "John",
                                isExpense: true,
                              ),

                              _transactionItem(
                                context,
                                icon: Icons.restaurant,
                                iconBgColor: Colors.grey.shade200,
                                title: "팀 점심",
                                date: "Oct 10",
                                amount: "128",
                                manager: "Sarah",
                                isExpense: true,
                              ),

                              _transactionItem(
                                context,
                                icon: Icons.payments,
                                iconBgColor: Colors.green.shade50,
                                title: "프로젝트",
                                date: "Oct 08",
                                amount: "2400",
                                manager: "Admin",
                                isExpense: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// FAB
            Positioned(
              right: 16,
              bottom: 90,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: primary,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SUMMARY CARD
  Widget _summaryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required String change,
    required Color primaryColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "$amount${AppStrings.get(context, 'currency')}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            change,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// TRANSACTION ITEM
  Widget _transactionItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String date,
    required String amount,
    required String manager,
    required bool isExpense,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isExpense ? '-' : '+'}$amount${AppStrings.get(context, 'currency')}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                manager,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
