const crypto = require('crypto');
const querystring = require('qs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('./walletService');

// Bảng quy đổi gói nạp: Giá VNĐ -> Số Tokens nhận được
const TOKEN_PACKAGES = [
  { id: 'pkg_10k', amount: 10000, tokens: 100, label: 'Gói Đồng (100 🪙)', bonusPercent: 0 },
  { id: 'pkg_20k', amount: 20000, tokens: 220, label: 'Gói Bạc (220 🪙)', bonusPercent: 10 },
  { id: 'pkg_50k', amount: 50000, tokens: 600, label: 'Gói Vàng (600 🪙)', bonusPercent: 20 },
  { id: 'pkg_100k', amount: 100000, tokens: 1300, label: 'Gói Kim Cương (1,300 🪙)', bonusPercent: 30 },
  { id: 'pkg_200k', amount: 200000, tokens: 2800, label: 'Gói Huyền Thoại (2,800 🪙)', bonusPercent: 40 },
  { id: 'pkg_500k', amount: 500000, tokens: 7500, label: 'Gói Đại Gia (7,500 🪙)', bonusPercent: 50 },
];

function formatDate(date) {
  const pad = (n) => (n < 10 ? '0' + n : n);
  const utc = date.getTime() + date.getTimezoneOffset() * 60000;
  const vnDate = new Date(utc + 7 * 3600000);
  const year = vnDate.getFullYear();
  const month = pad(vnDate.getMonth() + 1);
  const day = pad(vnDate.getDate());
  const hours = pad(vnDate.getHours());
  const minutes = pad(vnDate.getMinutes());
  const seconds = pad(vnDate.getSeconds());
  return `${year}${month}${day}${hours}${minutes}${seconds}`;
}

function sortObject(obj) {
  const sorted = {};
  const str = [];
  let key;
  for (key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      str.push(encodeURIComponent(key));
    }
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
    sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, '+');
  }
  return sorted;
}

/**
 * Tạo URL thanh toán VNPay
 */
async function createPaymentUrl({ userId, amount, tokens, bankCode = '', ipAddr = '127.0.0.1' }) {
  const tmnCode = process.env.VNP_TMN_CODE || 'D3IN2GT5';
  const secretKey = process.env.VNP_HASH_SECRET || 'RAXWGTCSBGHXNWLKJTGKUCJXYNMWEMTR';
  const vnpUrl = process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  const returnUrl = process.env.VNP_RETURN_URL || 'http://localhost:3000/api/vnpay/vnpay-return';

  const date = new Date();
  const createDate = formatDate(date);

  // Hết hạn sau 15 phút
  const expireDateObj = new Date(date.getTime() + 15 * 60 * 1000);
  const expireDate = formatDate(expireDateObj);

  // Mã giao dịch duy nhất
  const txnRef = `${formatDate(date)}${Math.floor(1000 + Math.random() * 9000)}`;
  const orderInfo = `Nap ${tokens} Tokens vao vi StudyTodoList`;

  // Lưu lịch sử thanh toán PENDING vào database
  try {
    await prisma.paymentTransaction.create({
      data: {
        userId,
        txnRef,
        amount: Number(amount),
        tokens: Number(tokens),
        status: 'PENDING',
        orderInfo,
      }
    });
  } catch (err) {
    console.warn('[VNPay] Không thể tạo PaymentTransaction trong DB (tiếp tục flow):', err.message);
  }

  let vnp_Params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: tmnCode,
    vnp_Locale: 'vn',
    vnp_CurrCode: 'VND',
    vnp_TxnRef: txnRef,
    vnp_OrderInfo: orderInfo,
    vnp_OrderType: 'other',
    vnp_Amount: Number(amount) * 100, // VNPay quy định nhân 100
    vnp_ReturnUrl: returnUrl,
    vnp_IpAddr: ipAddr,
    vnp_CreateDate: createDate,
    vnp_ExpireDate: expireDate,
  };

  if (bankCode && bankCode.trim().length > 0) {
    vnp_Params.vnp_BankCode = bankCode;
  }

  vnp_Params = sortObject(vnp_Params);

  const signData = querystring.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac('sha512', secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
  vnp_Params.vnp_SecureHash = signed;

  const paymentUrl = `${vnpUrl}?` + querystring.stringify(vnp_Params, { encode: false });

  return {
    paymentUrl,
    txnRef,
    amount,
    tokens,
  };
}

/**
 * Xử lý kết quả trả về từ Return URL
 */
async function processReturn(queryParams) {
  let vnp_Params = { ...queryParams };
  const currentUserId = queryParams.currentUserId;
  delete vnp_Params['currentUserId'];
  delete vnp_Params['format'];

  const secureHash = vnp_Params['vnp_SecureHash'];

  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  vnp_Params = sortObject(vnp_Params);

  const secretKey = process.env.VNP_HASH_SECRET || 'RAXWGTCSBGHXNWLKJTGKUCJXYNMWEMTR';
  const signData = querystring.stringify(vnp_Params, { encode: false });

  const hmac = crypto.createHmac('sha512', secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

  const txnRef = queryParams['vnp_TxnRef'];
  const responseCode = queryParams['vnp_ResponseCode'];
  const bankCode = queryParams['vnp_BankCode'];
  const vnpTransactionNo = queryParams['vnp_TransactionNo'];
  const payDateStr = queryParams['vnp_PayDate'];

  const isValidSignature = secureHash === signed;

  if (!isValidSignature) {
    return {
      success: false,
      message: 'Chữ ký không hợp lệ (Sai Secret Key hoặc dữ liệu bị thay đổi)',
      code: 'INVALID_SIGNATURE',
      txnRef,
    };
  }

  if (responseCode !== '00') {
    // Cập nhật trạng thái FAILED
    try {
      await prisma.paymentTransaction.updateMany({
        where: { txnRef },
        data: { status: 'FAILED' }
      });
    } catch (_) {}

    return {
      success: false,
      message: `Giao dịch không thành công (Mã lỗi: ${responseCode})`,
      code: responseCode,
      txnRef,
    };
  }

  // Giao dịch thành công (00) -> Cộng Token vào Ví User
  let paymentRecord = null;
  try {
    paymentRecord = await prisma.paymentTransaction.findUnique({
      where: { txnRef },
    });
  } catch (_) {}

  let tokensToAdd = 0;
  let userId = currentUserId || null;

  if (paymentRecord) {
    tokensToAdd = paymentRecord.tokens;
    userId = paymentRecord.userId || currentUserId;

    // Tránh xử lý lặp lại nếu đã SUCCESS
    if (paymentRecord.status === 'SUCCESS') {
      return {
        success: true,
        alreadyProcessed: true,
        message: 'Giao dịch đã được ghi nhận trước đó',
        tokens: tokensToAdd,
        txnRef,
      };
    }

    // Cập nhật SUCCESS
    try {
      await prisma.paymentTransaction.update({
        where: { id: paymentRecord.id },
        data: {
          status: 'SUCCESS',
          bankCode,
          vnpTransactionNo,
          paymentDate: new Date(),
        }
      });
    } catch (e) {
      console.error('[VNPay] Lỗi cập nhật status SUCCESS:', e.message);
    }
  } else {
    // Nếu không tìm thấy paymentRecord trong DB (do lỗi DB tạm thời), tính tokens từ vnp_Amount
    const amountInVnd = Number(queryParams['vnp_Amount']) / 100;
    const matchedPkg = TOKEN_PACKAGES.find((p) => p.amount === amountInVnd);
    tokensToAdd = matchedPkg ? matchedPkg.tokens : Math.floor(amountInVnd / 100);
  }

  // Cộng Tokens vào ví người dùng nếu xác định được userId
  if (userId && tokensToAdd > 0) {
    console.log(`[VNPay] Đang cộng +${tokensToAdd} Tokens cho User: ${userId}`);
    await walletService.adjustBalance(
      userId,
      tokensToAdd,
      'PURCHASE',
      `Nạp ${tokensToAdd} Tokens qua cổng VNPay (GD #${txnRef})`,
      txnRef
    );
    console.log(`[VNPay] Đã cộng thành công +${tokensToAdd} Tokens cho User: ${userId}`);
  } else {
    console.warn(`[VNPay] Không thể cộng Tokens: userId=${userId}, tokensToAdd=${tokensToAdd}`);
  }

  return {
    success: true,
    message: 'Thanh toán thành công! Tokens đã được cộng vào tài khoản.',
    tokens: tokensToAdd,
    amount: Number(queryParams['vnp_Amount']) / 100,
    txnRef,
  };
}

module.exports = {
  TOKEN_PACKAGES,
  createPaymentUrl,
  processReturn,
};
