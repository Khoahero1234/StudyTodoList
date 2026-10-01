const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_for_dev';

const generateTokens = (user) => {
    const accessToken = jwt.sign({ id: user.id, email: user.email, username: user.username }, JWT_SECRET, { expiresIn: '1d' });
    const refreshToken = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    return { accessToken, refreshToken };
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await prisma.user.findUnique({ where: { email } });
        
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        const { accessToken, refreshToken } = generateTokens(user);

        res.json({
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
                currentStreak: user.currentStreak,
                tokenBalance: user.tokenBalance,
                isPremium: user.isPremium,
                createdAt: user.createdAt
            },
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
                password: hashedPassword
            }
        });

        const { accessToken, refreshToken } = generateTokens(newUser);

        res.json({
            user: {
                id: newUser.id,
                email: newUser.email,
                username: newUser.username,
                currentStreak: newUser.currentStreak,
                tokenBalance: newUser.tokenBalance,
                isPremium: newUser.isPremium,
                createdAt: newUser.createdAt
            },
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
        const user = await prisma.user.findUnique({ where: { id: req.user.id } });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });
        
        res.json({
            id: user.id,
            email: user.email,
            username: user.username,
            currentStreak: user.currentStreak,
            tokenBalance: user.tokenBalance,
            isPremium: user.isPremium,
            createdAt: user.createdAt
        });
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
