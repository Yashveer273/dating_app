import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talk24loves/Api/AppConfig.dart';
import 'package:talk24loves/components/DottedWaveLoader.dart';

import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

import 'screens/caling_agent_dashboard/component/user_storage.dart';
import 'screens/userSection/model/user_model.dart';

class CashfreePayButton extends StatefulWidget {
  final double payableAmount;
  final double width;
  final double height;
  final Map<String, dynamic>? couponDetails;

  const CashfreePayButton({
    super.key,
    required this.payableAmount,
    this.width = double.infinity,
    this.height = 52,
    this.couponDetails,
  });

  @override
  State<CashfreePayButton> createState() => _CashfreePayButtonState();
}

class _CashfreePayButtonState extends State<CashfreePayButton> {
  final CFPaymentGatewayService cfPaymentGatewayService =
      CFPaymentGatewayService();

  bool isLoading = false;

  final String baseUrl = AppConfig.rootBaseUrl;

  @override
  void initState() {
    super.initState();
    cfPaymentGatewayService.setCallback(verifyPayment, onError);
  }

  final UserModel? user = UserStorage.getUser();
  Future<void> createPayment() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final body = {
        'amount': widget.payableAmount,
        'customerId': user?.id,
        'customerName': user?.name,

        'customerPhone': user?.phoneNumber,
      };

      if (widget.couponDetails != null) {
        body.addAll({
          'coupon_code': widget.couponDetails!['code'],
          'coupon_bonus':
              widget.couponDetails!['bonusAmount'] ??
              widget.couponDetails!['coupon_bonus'] ??
              0.0,
          'coupon_description': widget.couponDetails!['description'],
          'coupon_expires_at': widget.couponDetails!['expiresAt'],
          'bonus_type': widget.couponDetails!['bonusType'] ?? 'wallet_bonus',
          'is_extra_credit': widget.couponDetails!['isExtraCredit'] ?? true,
        });
      }

      final response = await http.post(
        Uri.parse('$baseUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Create Order Response: ${response.body}');

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final String orderId = data['order_id'];
      final String paymentSessionId = data['payment_session_id'];

      debugPrint('Order ID: $orderId');
      debugPrint('Payment Session ID: $paymentSessionId');

      await openCashfreeCheckout(
        orderId: orderId,
        paymentSessionId: paymentSessionId,
      );
    } catch (e) {
      debugPrint('Create Payment Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openCashfreeCheckout({
    required String orderId,
    required String paymentSessionId,
  }) async {
    try {
      final CFSession? session = createSession(
        orderId: orderId,
        paymentSessionId: paymentSessionId,
      );

      if (session == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      cfPaymentGatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
      debugPrint('Cashfree Exception: ${e.message}');
      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Checkout Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  CFSession? createSession({
    required String orderId,
    required String paymentSessionId,
  }) {
    try {
      return CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
    } on CFException catch (e) {
      debugPrint('Session Error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Session Error: $e');
      return null;
    }
  }

  void verifyPayment(String orderId) {
    debugPrint('Payment Callback');
    debugPrint('Order ID: $orderId');
    verifyPaymentFromBackend(orderId);
  }

  void onError(CFErrorResponse errorResponse, String orderId) {
    debugPrint('Cashfree Payment Error');
    debugPrint('Order ID: $orderId');
    debugPrint('Error: ${errorResponse.getMessage()}');

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> verifyPaymentFromBackend(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-status/$orderId'),
      );

      debugPrint('Payment Status Response: ${response.body}');

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Payment Verification Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : createPayment,
        child: isLoading
            ? const DottedWaveLoader(color: Colors.white, size: 6)
            : Text(
                'Pay ₹${widget.payableAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
