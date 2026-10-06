// File Name: wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/Api/UserApiService.dart';
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
  final ThemeController themeController = Get.find<ThemeController>();
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final apiService = UserApiService()..onInit();
    final balance = await apiService.fetchCurrentWalletBalance();

    if (mounted) setState(() => _walletBalance = balance);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  bool get isDarkMode => themeController.isDarkMode;

  RechargePack get activePack {
    if (selectedIndex != null) {
      return packs[selectedIndex!];
    }
    return RechargePack(
      amount: customAmountValue > 0 ? customAmountValue : 100,
    );
  }

  Widget _buildTopBar(bool isDarkMode, Color primaryText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: primaryText,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'My Wallet',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryText, size: 22),
            onPressed: () {
              // TODO: Open transaction history
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build individual recharge cards using Column/Row layout
  Widget _buildRechargeCard(RechargePack pack, int index) {
    final isSelected = selectedIndex == index;
    final cardColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final primaryText = isDarkMode
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondaryText = isDarkMode
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

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
          height: 64,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : borderColor,
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
                        style: TextStyle(
                          color: primaryText,
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
                              : secondaryText,
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
    final cardColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final primaryText = isDarkMode
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondaryText = isDarkMode
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    // Group packs into rows of 2 items each
    List<Widget> packRows = [];
    for (int i = 0; i < packs.length; i += 2) {
      List<Widget> rowChildren = [];
      rowChildren.add(_buildRechargeCard(packs[i], i));

      if (i + 1 < packs.length) {
        rowChildren.add(const SizedBox(width: 10));
        rowChildren.add(_buildRechargeCard(packs[i + 1], i + 1));
      } else {
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AppBackground(
          isDarkMode: isDarkMode,
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(isDarkMode, primaryText),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- REDESIGNED PROFESSIONAL BALANCE CARD ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E1E24)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF2C2C35)
                                  : const Color(0xFFEAEAEA),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL BALANCE',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF71717A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '₹',
                                        style: TextStyle(
                                          color: AppColors.primaryPink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _walletBalance?.toStringAsFixed(2) ??
                                            '--',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF18181B),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: AppColors.primaryPink,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: AppColors.primaryPink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- SELECT RECHARGE AMOUNT HEADER ---
                        Text(
                          'Select Recharge Amount',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // --- CUSTOM AMOUNT INPUT BOX ---
                        TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(color: primaryText, fontSize: 13),
                          onChanged: (value) {
                            setState(() {
                              selectedIndex = null;
                              customAmountValue = double.tryParse(value) ?? 0.0;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Or enter custom amount (e.g. 150)',
                            hintStyle: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              color: AppColors.primaryPink,
                              size: 18,
                            ),
                            filled: true,
                            fillColor: cardColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
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
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: activePack.amount <= 0
                                    ? null
                                    : () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              AddBalanceSummaryPopup(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
