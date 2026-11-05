const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_for_dev';

const generateTokens = (user) => {
    const accessToken = jwt.sign(
        { id: user.id, email: user.email, username: user.username, role: user.role },
        JWT_SECRET,
        { expiresIn: '1d' }
    );
    const refreshToken = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    return { accessToken, refreshToken };
};

const formatUserResponse = (user) => {
    const isPremiumActive = Boolean(
        user.premiumSub &&
        user.premiumSub.status === 'ACTIVE' &&
        new Date(user.premiumSub.endDate) > new Date()
    );

    return {
        id: user.id,
        email: user.email,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        role: user.role,
        isActive: user.isActive,
        emailVerified: user.isVerified,
        currentStreak: user.loginStreak?.currentStreak ?? 0,
        longestStreak: user.loginStreak?.longestStreak ?? 0,
        lastLoginDate: user.loginStreak?.lastLoginDate ?? null,
        tokenBalance: user.wallet?.balance ?? 0,
        isPremium: isPremiumActive,
        xp: user.xp ?? 0,
        level: user.level ?? 1,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
    };
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await prisma.user.findUnique({
            where: { email },
            include: {
                wallet: true,
                loginStreak: true,
                premiumSub: true
            }
        });
        
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        // Ensure user has a wallet initialized
        if (!user.wallet) {
            user.wallet = await prisma.wallet.create({
                data: { userId: user.id, balance: 0 }
            });
        }

        const { accessToken, refreshToken } = generateTokens(user);

        res.json({
            user: formatUserResponse(user),
            accessToken,
            refreshToken
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.register = async (req, res) => {
    try {
        const { email, username, password } = req.body;
        
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ success: false, message: 'Email already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await prisma.user.create({
            data: {
                email,
                username,
                password: hashedPassword,
                wallet: {
                    create: { balance: 0 }
                },
                loginStreak: {
                    create: {
                        currentStreak: 1,
                        longestStreak: 1,
                        lastLoginDate: new Date()
                    }
                }
            },
            include: {
                wallet: true,
                loginStreak: true,
                premiumSub: true
            }
        });

        const { accessToken, refreshToken } = generateTokens(newUser);

        res.json({
            user: formatUserResponse(newUser),
            accessToken,
            refreshToken
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.logout = (req, res) => {
    res.json({ success: true, message: 'Logged out' });
};

exports.refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh token required' });
        
        const decoded = jwt.verify(refreshToken, JWT_SECRET);
        const user = await prisma.user.findUnique({ where: { id: decoded.id } });
        
        if (!user) throw new Error('User not found');
        
        const tokens = generateTokens(user);
        res.json({
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken
        });
    } catch (e) {
        res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }
};

exports.getCurrentUser = async (req, res) => {
    try {
        const user = await prisma.user.findUnique({
            where: { id: req.user.id },
            include: {
                wallet: true,
                loginStreak: true,
                premiumSub: true
            }
        });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        if (!user.wallet) {
            user.wallet = await prisma.wallet.create({
                data: { userId: user.id, balance: 0 }
            });
        }
        
        res.json(formatUserResponse(user));
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// THÊM MỚI: Cập nhật thông tin Profile
// ==========================================
exports.updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { displayName, username, bio, avatarUrl } = req.body;

        if (username) {
            const existingUser = await prisma.user.findFirst({
                where: {
                    username,
                    NOT: { id: userId }
                }
            });
            if (existingUser) {
                return res.status(400).json({ success: false, message: 'Username already taken' });
            }
        }

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                displayName,
                username,
                bio,
                avatarUrl
            },
            include: {
                wallet: true,
                premiumSub: true,
                loginStreak: true
            }
        });

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: {
                id: updatedUser.id,
                email: updatedUser.email,
                username: updatedUser.username,
                displayName: updatedUser.displayName,
                avatarUrl: updatedUser.avatarUrl,
                bio: updatedUser.bio,
                currentStreak: updatedUser.loginStreak?.currentStreak || 0,
                tokenBalance: updatedUser.wallet?.balance || 0,
                isPremium: updatedUser.premiumSub?.status === 'ACTIVE',
                createdAt: updatedUser.createdAt
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// THÊM MỚI: Đổi mật khẩu
// ==========================================
exports.changePassword = async (req, res) => {
    try {
        const userId = req.user.id;
        const { oldPassword, newPassword } = req.body;

        if (!oldPassword || !newPassword) {
            return res.status(400).json({ success: false, message: 'Please provide old and new password' });
        }

        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Incorrect old password' });
        }

        const hashedNewPassword = await bcrypt.hash(newPassword, 10);

        await prisma.user.update({
            where: { id: userId },
            data: { password: hashedNewPassword }
        });

        res.json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.forgotPassword = (req, res) => {
    res.json({ success: true, message: 'Password reset link sent' });
};

exports.resetPassword = (req, res) => {
    res.json({ success: true, message: 'Password reset successful' });
};
