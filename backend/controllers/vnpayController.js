const jwt = require('jsonwebtoken');
const vnpayService = require('../services/vnpayService');

/**
 * Lấy danh sách các gói nạp token & khuyến mãi
 */
exports.getPackages = (req, res) => {
  res.json({
    success: true,
    data: vnpayService.TOKEN_PACKAGES,
  });
};

/**
 * Tạo link thanh toán VNPay
 */
exports.createPaymentUrl = async (req, res) => {
  try {
    const userId = req.user.id;
    const { packageId, amount, tokens, bankCode } = req.body;

    let targetAmount = amount;
    let targetTokens = tokens;

    if (packageId) {
      const pkg = vnpayService.TOKEN_PACKAGES.find((p) => p.id === packageId);
      if (pkg) {
        targetAmount = pkg.amount;
        targetTokens = pkg.tokens;
      }
    }

    if (!targetAmount || targetAmount < 5000) {
      return res.status(400).json({
        success: false,
        message: 'Số tiền nạp tối thiểu là 5,000 VNĐ',
      });
    }

    if (!targetTokens || targetTokens <= 0) {
      targetTokens = Math.floor(targetAmount / 100);
    }

    const ipAddr =
      req.headers['x-forwarded-for'] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      '127.0.0.1';

    const result = await vnpayService.createPaymentUrl({
      userId,
      amount: targetAmount,
      tokens: targetTokens,
      bankCode,
      ipAddr,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('[VNPay Controller] createPaymentUrl error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Xử lý Return URL từ VNPay khi thanh toán xong
 */
exports.vnpayReturn = async (req, res) => {
  try {
    // Trích xuất userId từ JWT Token nếu có (khi Mobile App gọi API trực tiếp)
    let currentUserId = null;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      try {
        const token = req.headers.authorization.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_jwt_key_for_dev');
        currentUserId = decoded.id;
      } catch (_) {}
    }

    const result = await vnpayService.processReturn({
      ...req.query,
      currentUserId,
    });

    // Nếu client yêu cầu JSON (Mobile App DioClient gọi API để xác thực và cộng token)
    if (req.xhr || req.headers.accept?.includes('application/json') || req.query.format === 'json') {
      return res.json({
        success: result.success,
        data: result,
      });
    }

    // Trả về HTML thân thiện cho WebView của Mobile App
    const statusColor = result.success ? '#4CAF50' : '#F44336';
    const statusIcon = result.success ? '✓' : '✗';
    const statusTitle = result.success ? 'Thanh toán thành công!' : 'Thanh toán không thành công';
    const subText = result.success
      ? `Bạn đã nhận được <strong>+${result.tokens} Tokens 🪙</strong> vào ví.`
      : result.message || 'Giao dịch bị hủy hoặc xảy ra lỗi.';

    const html = `
      <!DOCTYPE html>
      <html lang="vi">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Kết quả thanh toán VNPay</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #121212;
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            padding: 20px;
            box-sizing: border-box;
          }
          .card {
            background-color: #1E1E2E;
            border-radius: 20px;
            padding: 30px 24px;
            text-align: center;
            max-width: 400px;
            width: 100%;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
          }
          .icon-circle {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background-color: ${statusColor}22;
            color: ${statusColor};
            font-size: 40px;
            line-height: 80px;
            margin: 0 auto 20px auto;
            border: 2px solid ${statusColor};
          }
          h2 { margin: 0 0 10px 0; font-size: 22px; color: ${statusColor}; }
          p { color: #BBB; line-height: 1.5; font-size: 15px; margin: 10px 0; }
          .txn-info {
            background: #28283E;
            border-radius: 10px;
            padding: 12px;
            margin: 20px 0;
            font-size: 13px;
            color: #AAA;
            text-align: left;
          }
          .txn-info div { margin-bottom: 6px; }
          .txn-info span { color: #FFF; font-weight: bold; float: right; }
          .btn {
            display: inline-block;
            background: #6C63FF;
            color: white;
            padding: 12px 30px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: bold;
            font-size: 16px;
            margin-top: 10px;
            width: 100%;
            box-sizing: border-box;
            border: none;
            cursor: pointer;
          }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="icon-circle">${statusIcon}</div>
          <h2>${statusTitle}</h2>
          <p>${subText}</p>
          <div class="txn-info">
            <div>Mã GD: <span>${result.txnRef || '---'}</span></div>
            ${result.tokens ? `<div>Tokens: <span>+${result.tokens} 🪙</span></div>` : ''}
            ${result.amount ? `<div>Số tiền: <span>${result.amount.toLocaleString('vi-VN')} đ</span></div>` : ''}
          </div>
          <button class="btn" onclick="window.close();">Quay lại ứng dụng</button>
        </div>
      </body>
      </html>
    `;

    res.send(html);
  } catch (error) {
    console.error('[VNPay Controller] vnpayReturn error:', error);
    res.status(500).send('<h3>Đã xảy ra lỗi khi xử lý kết quả thanh toán.</h3>');
  }
};

/**
 * Webhook IPN cho VNPay
 */
exports.vnpayIpn = async (req, res) => {
  try {
    const result = await vnpayService.processReturn(req.query);
    if (result.success) {
      res.status(200).json({ RspCode: '00', Message: 'Confirm Success' });
    } else if (result.code === 'INVALID_SIGNATURE') {
      res.status(200).json({ RspCode: '97', Message: 'Fail checksum' });
    } else {
      res.status(200).json({ RspCode: '01', Message: 'Order not found or error' });
    }
  } catch (error) {
    console.error('[VNPay Controller] vnpayIpn error:', error);
    res.status(200).json({ RspCode: '99', Message: 'Unknow error' });
  }
};
