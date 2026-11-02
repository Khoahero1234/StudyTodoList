const walletService = require('../services/walletService');

exports.getWalletInfo = async (req, res) => {
    try {
        const userId = req.user.id;
        const wallet = await walletService.getWallet(userId);
        res.json({
            success: true,
            data: {
                balance: wallet.balance,
                updatedAt: wallet.updatedAt,
                recentTransactions: wallet.transactions
            }
        });
    } catch (error) {
        console.error('Error in getWalletInfo:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getTransactionHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;

        const result = await walletService.getTransactions(userId, page, limit);
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Error in getTransactionHistory:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};
