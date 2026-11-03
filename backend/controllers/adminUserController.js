const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// GET /admin/users — Danh sách toàn bộ user (có phân trang + search)
exports.getAllUsers = async (req, res) => {
    try {
        const { search, role, page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const where = { deletedAt: null };
        if (role) where.role = role;
        if (search) {
            where.OR = [
                { username: { contains: search, mode: 'insensitive' } },
                { email: { contains: search, mode: 'insensitive' } },
                { displayName: { contains: search, mode: 'insensitive' } }
            ];
        }

        const [users, total] = await Promise.all([
            prisma.user.findMany({
                where,
                select: {
                    id: true, email: true, username: true,
                    displayName: true, avatarUrl: true,
                    role: true, isActive: true, isVerified: true,
                    xp: true, level: true, createdAt: true
                },
                skip,
                take: parseInt(limit),
                orderBy: { createdAt: 'desc' }
            }),
            prisma.user.count({ where })
        ]);

        res.json({ success: true, data: users, total, page: parseInt(page), limit: parseInt(limit) });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// PATCH /admin/users/:id/role — Đổi role (CUSTOMER ↔ ADMIN)
exports.changeUserRole = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.body;

        if (!['CUSTOMER', 'ADMIN'].includes(role)) {
            return res.status(400).json({ success: false, message: 'role phải là CUSTOMER hoặc ADMIN' });
        }

        // Không cho tự đổi role của chính mình
        if (id === req.user.id) {
            return res.status(400).json({ success: false, message: 'Không thể tự thay đổi role của mình' });
        }

        const user = await prisma.user.findFirst({ where: { id, deletedAt: null } });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User không tồn tại' });
        }

        const updated = await prisma.user.update({
            where: { id },
            data: { role },
            select: { id: true, email: true, username: true, role: true }
        });

        res.json({ success: true, data: updated, message: `Đã đổi role thành ${role}` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// PATCH /admin/users/:id/ban — Toggle isActive (ban / unban)
exports.toggleUserBan = async (req, res) => {
    try {
        const { id } = req.params;

        if (id === req.user.id) {
            return res.status(400).json({ success: false, message: 'Không thể tự ban tài khoản của mình' });
        }

        const user = await prisma.user.findFirst({ where: { id, deletedAt: null } });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User không tồn tại' });
        }

        const updated = await prisma.user.update({
            where: { id },
            data: { isActive: !user.isActive },
            select: { id: true, email: true, username: true, isActive: true }
        });

        const action = updated.isActive ? 'Đã mở khóa' : 'Đã ban';
        res.json({ success: true, data: updated, message: `${action} tài khoản ${updated.username}` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
