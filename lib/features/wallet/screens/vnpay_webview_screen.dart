// lib/features/wallet/screens/vnpay_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/vnpay_remote_datasource.dart';

class VNPayWebViewScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final int expectedTokens;
  final int amount;

  const VNPayWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.expectedTokens,
    required this.amount,
  });

  @override
  ConsumerState<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends ConsumerState<VNPayWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isFinished = false;
  String? _webError;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted && _webError != null) {
              setState(() => _webError = null);
            }
            _checkPaymentResult(url);
          },
          onPageFinished: (String url) {
            _checkPaymentResult(url);
          },
          onWebResourceError: (WebResourceError error) {
            // Chỉ ghi nhận lỗi khi không tải được trang chính
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() {
                _webError = error.description.isNotEmpty
                    ? error.description
                    : 'Không thể phân giải tên miền (ERR_NAME_NOT_RESOLVED)';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkPaymentResult(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _checkPaymentResult(String url) {
    if (_isFinished) return true;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Kiểm tra xem URL có chứa tham số kết quả của VNPay không
    if (uri.queryParameters.containsKey('vnp_ResponseCode')) {
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      _isFinished = true;

      if (responseCode == '00') {
        _processPaymentConfirmation(uri.queryParameters);
      } else {
        _handleFailure(responseCode);
      }
      return true;
    }

    return false;
  }

  /// Gửi kết quả giao dịch về Backend để xác thực chữ ký và cộng Tokens vào database
  Future<void> _processPaymentConfirmation(Map<String, String> queryParameters) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Đang cộng Tokens vào ví...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final dataSource = ref.read(vnpayRemoteDataSourceProvider);
      final result = await dataSource.confirmPaymentReturn(queryParameters);
      if (!mounted) return;

      // Đóng loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      final tokensAdded = (result['tokens'] as num?)?.toInt() ?? widget.expectedTokens;
      _handleSuccess(tokensAdded);
    } catch (e) {
      if (!mounted) return;
      // Đóng loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      _handleFailure('Lỗi cập nhật số dư: $e');
    }
  }

  void _handleSuccess(int tokensReceived) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
            SizedBox(width: 10),
            Text('Nạp Token Thành Công!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao dịch qua cổng VNPay đã được xác thực và cộng vào ví của bạn.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🪙 Nhận được:', style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Text(
                    '+$tokensReceived Tokens',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // đóng dialog
              Navigator.of(context).pop(true); // đóng webview với kết quả true
            },
            child: const Text('Tuyệt vời', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleFailure(String? code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Thanh toán thất bại', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          code == '24'
              ? 'Bạn đã hủy giao dịch thanh toán.'
              : 'Giao dịch không thể hoàn tất (Mã phản hồi: $code). Vui lòng thử lại sau.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hủy thanh toán?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Giao dịch nạp Tokens chưa hoàn tất. Bạn có chắc chắn muốn thoát?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Ở lại', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Thoát', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cổng thanh toán VNPay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                'Nạp ${widget.expectedTokens} Tokens (${widget.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ)',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() => _webError = null);
                _controller.reload();
              },
            ),
          ],
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3.0),
                  child: LinearProgressIndicator(
                    value: _progress / 100.0,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            Expanded(
              child: _webError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 56),
                            const SizedBox(height: 16),
                            const Text(
                              'Không thể kết nối cổng VNPay',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thiết bị bị gián đoạn mạng hoặc lỗi DNS (${_webError ?? ''}).\nNhấn nút bên dưới để thử lại.',
                              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              label: const Text('Thử lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() => _webError = null);
                                _controller.loadRequest(Uri.parse(widget.paymentUrl));
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
            // Khung hỗ trợ xem & sao chép thông tin thẻ test để tự điền trên web VNPay
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF181824),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Thẻ test NCB: 9704198526191432198',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tên: NGUYEN VAN A | Ngày: 07/15 | OTP: 123456',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: '9704198526191432198'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép số thẻ: 9704198526191432198'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.copy, color: AppColors.primary, size: 13),
                            SizedBox(width: 4),
                            Text('Copy thẻ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
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
    );
  }
}
