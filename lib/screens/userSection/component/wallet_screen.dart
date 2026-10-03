// File Name: wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/userSection/component/add_balance_popup.dart';

class RechargePack {
  final double amount;
  final double extraPercent;
  final String? badge; // e.g., "POPULAR", "VALUE PACK"

  const RechargePack({
    required this.amount,
    this.extraPercent = 0.0,
    this.badge,
  });

  double get effectiveAmount => amount + (amount * (extraPercent / 100));
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<RechargePack> packs = const [
    RechargePack(amount: 50),
    RechargePack(amount: 100, extraPercent: 6.0, badge: 'POPULAR'),
    RechargePack(amount: 250, extraPercent: 10.0),
    RechargePack(amount: 500, extraPercent: 15.0, badge: 'VALUE'),
    RechargePack(amount: 1000, extraPercent: 20.0),
    RechargePack(amount: 2500, extraPercent: 25.0, badge: 'BEST'),
  ];

  int? selectedIndex = 1; // Default selected pack
  final TextEditingController _customAmountController = TextEditingController();
  double customAmountValue = 0.0;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  RechargePack get activePack {
    if (selectedIndex != null) {
      return packs[selectedIndex!];
    }
    return RechargePack(
      amount: customAmountValue > 0 ? customAmountValue : 100,
    );
  }

  // Helper method to build individual recharge cards using Column/Row layout
  Widget _buildRechargeCard(RechargePack pack, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
            customAmountValue = 0.0;
            _customAmountController.clear();
            FocusScope.of(context).unfocus();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64, // Reduced height for a compact, neat look
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.darkBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (pack.badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(11),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      pack.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₹${pack.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.darkPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pack.extraPercent > 0
                            ? '+${pack.extraPercent.toStringAsFixed(0)}% Extra'
                            : 'Standard',
                        style: TextStyle(
                          color: pack.extraPercent > 0
                              ? AppColors.otpSuccessGreen
                              : AppColors.darkSecondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group packs into rows of 2 items each
    List<Widget> packRows = [];
    for (int i = 0; i < packs.length; i += 2) {
      List<Widget> rowChildren = [];
      rowChildren.add(_buildRechargeCard(packs[i], i));

      if (i + 1 < packs.length) {
        rowChildren.add(
          const SizedBox(width: 10),
        ); // Gap between items in a row
        rowChildren.add(_buildRechargeCard(packs[i + 1], i + 1));
      } else {
        // If odd number of items, add an invisible expanded spacer to keep alignment
        rowChildren.add(const SizedBox(width: 10));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      packRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: rowChildren),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgTop,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: AppColors.darkPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            onPressed: () {
              // TODO: Open transaction history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AVAILABLE BALANCE CARD WITH BORDER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.pinkGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.darkBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '₹ 450.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SELECT RECHARGE AMOUNT HEADER ---
            const Text(
              'Select Recharge Amount',
              style: TextStyle(
                color: AppColors.darkPrimaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // --- CUSTOM AMOUNT INPUT BOX ---
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: AppColors.darkPrimaryText,
                fontSize: 13,
              ),
              onChanged: (value) {
                setState(() {
                  selectedIndex = null;
                  customAmountValue = double.tryParse(value) ?? 0.0;
                });
              },
              decoration: InputDecoration(
                hintText: 'Or enter custom amount (e.g. 150)',
                hintStyle: const TextStyle(
                  color: AppColors.darkSecondaryText,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.primaryPink,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.darkCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryPink,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- RECHARGE PACKS COLUMN/ROW SYSTEM (NO GRIDVIEW) ---
            ...packRows,

            const SizedBox(height: 12),

            // --- COMPACT CENTERED ACTION BUTTON WITH BORDER ---
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.darkBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      elevation: 0,
                    ),
                    onPressed: activePack.amount <= 0
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddBalanceSummaryPopup(
                                selectedPack: activePack,
                              ),
                            );
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Top-Up ₹${activePack.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
