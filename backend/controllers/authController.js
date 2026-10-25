const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_for_dev';

const generateTokens = (user) => {
    const accessToken = jwt.sign({ id: user.id, email: user.email, username: user.username }, JWT_SECRET, { expiresIn: '1d' });
    const refreshToken = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    return { accessToken, refreshToken };
};

const formatUserResponse = (user) => {
    return {
        id: user.id,
        email: user.email,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        role: (user.role || 'customer').toLowerCase(),
        isActive: user.isActive !== undefined ? user.isActive : true,
        isVerified: Boolean(user.isVerified),
        emailVerified: Boolean(user.isVerified),
        xp: user.xp || 0,
        level: user.level || 1,
        currentStreak: user.loginStreak ? user.loginStreak.currentStreak : 0,
        longestStreak: user.loginStreak ? user.loginStreak.longestStreak : 0,
        lastLoginDate: user.loginStreak && user.loginStreak.lastLoginDate ? user.loginStreak.lastLoginDate : null,
        tokenBalance: user.wallet ? user.wallet.balance : 0,
        isPremium: Boolean(user.premiumSub && user.premiumSub.status === 'ACTIVE'),
        createdAt: user.createdAt ? user.createdAt.toISOString() : new Date().toISOString(),
        updatedAt: user.updatedAt ? user.updatedAt.toISOString() : new Date().toISOString()
    };
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password are required' });
        }

        const user = await prisma.user.findUnique({
            where: { email },
            include: {
                wallet: true,
                loginStreak: true,
                premiumSub: true
            }
        });

        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ success: false, message: 'Invalid email or password' });
        }

        const { accessToken, refreshToken } = generateTokens(user);

        res.json({
            success: true,
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
        const { email, username, password, displayName } = req.body;

        if (!email || !username || !password) {
            return res.status(400).json({ success: false, message: 'Email, username, and password are required' });
        }

        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [{ email }, { username }]
            }
        });

        if (existingUser) {
            const field = existingUser.email === email ? 'Email' : 'Username';
            return res.status(400).json({ success: false, message: `${field} already exists` });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const verifyToken = crypto.randomBytes(32).toString('hex');

        const newUser = await prisma.user.create({
            data: {
                email,
                username,
                displayName: displayName || username,
                password: hashedPassword,
                verifyToken,
                wallet: {
                    create: { balance: 50 } // initial balance bonus
                },
                loginStreak: {
                    create: { currentStreak: 1, longestStreak: 1, lastLoginDate: new Date() }
                }
            },
            include: {
                wallet: true,
                loginStreak: true,
                premiumSub: true
            }
        });

        const { accessToken, refreshToken } = generateTokens(newUser);

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            user: formatUserResponse(newUser),
            verifyToken, // returned for testing/verification in dev environment
            accessToken,
            refreshToken
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.logout = (req, res) => {
    res.json({ success: true, message: 'Logged out successfully' });
};

exports.refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh token required' });

        const decoded = jwt.verify(refreshToken, JWT_SECRET);
        const user = await prisma.user.findUnique({ where: { id: decoded.id } });

        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        const tokens = generateTokens(user);
        res.json({
            success: true,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken
        });
    } catch (e) {
        res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
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

        res.json({
            success: true,
            user: formatUserResponse(user)
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            // Return success even if email not found for security reasons
            return res.json({ success: true, message: 'If email exists, a password reset token has been generated' });
        }

        const resetToken = crypto.randomBytes(32).toString('hex');
        await prisma.user.update({
            where: { id: user.id },
            data: { verifyToken: resetToken }
        });

        res.json({
            success: true,
            message: 'Password reset link sent to email',
            resetToken // returned for dev/testing ease
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.resetPassword = async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        if (!token || !newPassword) {
            return res.status(400).json({ success: false, message: 'Token and new password are required' });
        }

        const user = await prisma.user.findFirst({
            where: { verifyToken: token }
        });

        if (!user) {
            return res.status(400).json({ success: false, message: 'Invalid or expired reset token' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await prisma.user.update({
            where: { id: user.id },
            data: {
                password: hashedPassword,
                verifyToken: null
            }
        });

        res.json({ success: true, message: 'Password reset successful' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.verifyEmail = async (req, res) => {
    try {
        const { token } = req.body;
        if (!token) {
            return res.status(400).json({ success: false, message: 'Verification token is required' });
        }

        const user = await prisma.user.findFirst({
            where: { verifyToken: token }
        });

        if (!user) {
            return res.status(400).json({ success: false, message: 'Invalid verification token' });
        }

        await prisma.user.update({
            where: { id: user.id },
            data: {
                isVerified: true,
                verifyToken: null
            }
        });

        res.json({ success: true, message: 'Email verified successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
