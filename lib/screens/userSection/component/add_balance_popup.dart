// File: lib/components/add_balance_summary_popup.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/cashfree_payment.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/userSection/component/wallet_screen.dart';

class CouponOffer {
  final String code;
  final double bonusAmount;
  final DateTime? expiresAt;
  final String description;

  const CouponOffer({
    required this.code,
    required this.bonusAmount,
    this.expiresAt,
    required this.description,
  });
}

class AddBalanceSummaryPopup extends StatefulWidget {
  final RechargePack selectedPack;

  const AddBalanceSummaryPopup({super.key, required this.selectedPack});

  @override
  State createState() => _AddBalanceSummaryPopupState();
}

class _AddBalanceSummaryPopupState extends State<AddBalanceSummaryPopup>
    with SingleTickerProviderStateMixin {
  final List<CouponOffer> coupons = [
    CouponOffer(
      code: 'WELCOME20',
      bonusAmount: 10.0,
      expiresAt: DateTime(2026, 10, 20),
      description: 'Welcome bonus',
    ),
    CouponOffer(
      code: 'FLASH50',
      bonusAmount: 50.0,
      expiresAt: DateTime(2026, 11, 05),
      description: 'Weekend flash offer',
    ),
    CouponOffer(
      code: 'VIP100',
      bonusAmount: 100.0,
      expiresAt: DateTime(2026, 12, 31),
      description: 'VIP loyalty reward',
    ),
  ];

  CouponOffer? selectedCoupon;
  late AnimationController _partyEffectController;
  final ThemeController themeController = Get.find<ThemeController>();
  bool get isDarkMode => themeController.isDarkMode;
  @override
  void initState() {
    super.initState();
    selectedCoupon = coupons.first;
    _partyEffectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  double get baseAmount => widget.selectedPack.amount;
  double get extraPercentAmount =>
      baseAmount * (widget.selectedPack.extraPercent / 100);
  double get couponBonus => selectedCoupon?.bonusAmount ?? 0.0;
  double get taxes => baseAmount * 0.18;
  double get totalPayable => baseAmount + taxes;
  double get totalEffectiveWalletCredit =>
      baseAmount + extraPercentAmount + couponBonus;
  double get virtualBonusAmount => extraPercentAmount + couponBonus;

  String _formatCouponLabel(CouponOffer coupon) {
    final dateText = coupon.expiresAt != null
        ? '${coupon.expiresAt!.day.toString().padLeft(2, '0')}/${coupon.expiresAt!.month.toString().padLeft(2, '0')}/${coupon.expiresAt!.year}'
        : 'No expiry';

    return '${coupon.code} • Add ₹${coupon.bonusAmount.toStringAsFixed(0)} Bonus';
  }

  @override
  void dispose() {
    _partyEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    final sectionColor = isDarkMode
        ? AppColors.darkBgMid
        : AppColors.lightBgMid;
    final borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final primaryTextColor = isDarkMode
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Stack(
      children: [
        if (widget.selectedPack.extraPercent > 0)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _partyEffectController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ProfessionalPartyParticlePainter(
                    _partyEffectController.value,
                  ),
                );
              },
            ),
          ),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: AppColors.primaryPink, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Summary',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Recharge Amount',
                      '₹${baseAmount.toStringAsFixed(2)}',
                      textColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Taxes & Charges (18%)',
                      '₹${taxes.toStringAsFixed(2)}',
                      textColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Virtual wallet bonus',
                      '+ ₹${virtualBonusAmount.toStringAsFixed(2)}',
                      isGreen: true,
                      textColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    Divider(color: borderColor, height: 16),
                    _buildSummaryRow(
                      'Actual pay',
                      '₹${totalPayable.toStringAsFixed(2)}',
                      isBold: true,
                      textColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Apply Coupon',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CouponOffer?>(
                    value: selectedCoupon,
                    dropdownColor: surfaceColor,
                    isExpanded: true,
                    style: TextStyle(color: primaryTextColor),
                    items: [
                      DropdownMenuItem<CouponOffer?>(
                        value: null,
                        child: Text(
                          'No Coupon Applied',
                          style: TextStyle(color: primaryTextColor),
                        ),
                      ),
                      ...coupons.map((coupon) {
                        return DropdownMenuItem<CouponOffer?>(
                          value: coupon,
                          child: Text(
                            _formatCouponLabel(coupon),
                            style: TextStyle(color: primaryTextColor),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => selectedCoupon = val),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CashfreePayButton(
                payableAmount: totalPayable,
                couponDetails: selectedCoupon == null
                    ? null
                    : {
                        'code': selectedCoupon!.code,
                        'bonusAmount': selectedCoupon!.bonusAmount,
                        'description': selectedCoupon!.description,
                        'expiresAt': selectedCoupon!.expiresAt
                            ?.toIso8601String(),
                        'bonusType': 'wallet_bonus',
                        'isExtraCredit': true,
                        'coupon_bonus': selectedCoupon!.bonusAmount,
                      },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    bool isGreen = false,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isBold ? textColor : secondaryTextColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isGreen
                ? AppColors.otpSuccessGreen
                : (isBold ? textColor : secondaryTextColor),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ProfessionalPartyParticlePainter extends CustomPainter {
  final double progress;
  ProfessionalPartyParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint();

    for (int i = 0; i < 25; i++) {
      final x =
          (random.nextDouble() * size.width +
              (progress * 40 * (i % 2 == 0 ? 1 : -1))) %
          size.width;
      final y =
          (random.nextDouble() * size.height + (progress * 80 * i)) %
          size.height;

      paint.color = [
        AppColors.primaryPink,
        AppColors.pinkLight,
        Colors.amberAccent,
      ][i % 3].withValues(alpha: 0.5);

      canvas.drawCircle(Offset(x, y), random.nextDouble() * 3 + 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ProfessionalPartyParticlePainter oldDelegate) =>
      true;
}
