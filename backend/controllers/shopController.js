// backend/controllers/shopController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const productDto = require('../dtos/productDto');

let _isSeedingShop = false;

async function ensureDefaultShopData() {
    if (_isSeedingShop) return;
    const count = await prisma.product.count();
    if (count > 0) return;

    _isSeedingShop = true;
    try {
        const defaultCategories = [
            {
                name: 'Giao diện & Theme',
                description: 'Đổi màu sắc và chủ đề không gian học tập',
                sortOrder: 1
            },
            {
                name: 'Khung Avatar & Huy hiệu',
                description: 'Trang trí hồ sơ cá nhân nổi bật trong phòng học',
                sortOrder: 2
            },
            {
                name: 'Vật phẩm Hỗ trợ',
                description: 'Tăng XP, bảo vệ chuỗi ngày học (Streak Freeze)',
                sortOrder: 3
            },
            {
                name: 'Âm thanh & Nhạc nền',
                description: 'Gói âm thanh Lofi, tiếng mưa hỗ trợ Pomodoro',
                sortOrder: 4
            }
        ];

        const categoryMap = {};
        for (const cat of defaultCategories) {
            const created = await prisma.productCategory.upsert({
                where: { name: cat.name },
                update: {},
                create: cat
            });
            categoryMap[cat.name] = created.id;
        }

        const defaultProducts = [
            {
                name: ' Bùa Hộ Mệnh Streak (Streak Freeze)',
                description: 'Bảo vệ chuỗi ngày đăng nhập học tập liên tiếp của bạn không bị mất nếu lỡ quên 1 ngày.',
                price: 50,
                rarity: 'RARE',
                stock: 20,
                discountPct: 10,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Vật phẩm Hỗ trợ']
            },
            {
                name: 'Thuốc Nhân Đôi XP (2x XP Boost)',
                description: 'Nhân đôi lượng XP nhận được khi hoàn thành Task và phiên Pomodoro trong 24 giờ.',
                price: 40,
                rarity: 'UNCOMMON',
                stock: 30,
                discountPct: 0,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Vật phẩm Hỗ trợ']
            },
            {
                name: 'Theme Cyberpunk Neon',
                description: 'Giao diện học tập phong cách Cyberpunk rực rỡ sắc tím & xanh neon tạo cảm hứng lập trình.',
                price: 120,
                rarity: 'EPIC',
                stock: -1,
                discountPct: 15,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Giao diện & Theme']
            },
            {
                name: 'Theme Rừng Xanh Tỉnh Thức',
                description: 'Màu xanh dịu mắt giúp tập trung đọc sách và ôn thi trong thời gian dài không mỏi mắt.',
                price: 80,
                rarity: 'COMMON',
                stock: -1,
                discountPct: 0,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Giao diện & Theme']
            },
            {
                name: 'Khung Avatar Vương Miện Học Bá',
                description: 'Khung viền vàng lấp lánh hiển thị quanh ảnh đại diện trong Study Room và Bảng xếp hạng.',
                price: 200,
                rarity: 'LEGENDARY',
                stock: 10,
                discountPct: 20,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Khung Avatar & Huy hiệu']
            },
            {
                name: 'Huy Hiệu Chiến Thần Deadline',
                description: 'Huy hiệu vinh danh những người dùng luôn hoàn thành công việc trước thời hạn.',
                price: 60,
                rarity: 'RARE',
                stock: 50,
                discountPct: 0,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Khung Avatar & Huy hiệu']
            },
            {
                name: 'Gói Âm Thanh Mưa Rơi & Lofi Chill',
                description: 'Bộ âm thanh trắng (White Noise) kết hợp nhạc Lofi nhẹ nhàng cho phiên Pomodoro.',
                price: 35,
                rarity: 'COMMON',
                stock: -1,
                discountPct: 0,
                isAvailable: true,
                isPremiumOnly: false,
                categoryId: categoryMap['Âm thanh & Nhạc nền']
            }
        ];

        for (const prod of defaultProducts) {
            const exists = await prisma.product.findFirst({ where: { name: prod.name } });
            if (!exists && prod.categoryId) {
                await prisma.product.create({ data: prod });
            }
        }
    } catch (e) {
        console.error('Error auto-seeding default shop data:', e.message);
    } finally {
        _isSeedingShop = false;
    }
}

exports.getProducts = async (req, res) => {
    try {
        await ensureDefaultShopData();

        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const { search, categoryId, rarity, premiumOnly } = req.query;

        const where = {
            isAvailable: true,
            deletedAt: null
        };

        if (search) {
            where.OR = [
                { name: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } }
            ];
        }
        if (categoryId) {
            where.categoryId = categoryId;
        }
        if (rarity) {
            where.rarity = rarity.toString().toUpperCase();
        }
        if (premiumOnly !== undefined) {
            where.isPremiumOnly = premiumOnly === 'true' || premiumOnly === true;
        }

        const [products, total] = await Promise.all([
            prisma.product.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: { category: true }
            }),
            prisma.product.count({ where })
        ]);

        res.json({
            success: true,
            data: {
                products: productDto.formatProductList(products),
                pagination: {
                    page,
                    limit,
                    total,
                    totalPages: Math.ceil(total / limit) || 1
                }
            }
        });
    } catch (error) {
        console.error('Error in getProducts:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};

exports.getProductById = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await prisma.product.findFirst({
            where: { id, deletedAt: null },
            include: { category: true }
        });

        if (!product) {
            return res.status(404).json({ success: false, message: 'Sản phẩm không tồn tại', error: 'Product not found' });
        }

        res.json({
            success: true,
            data: productDto.formatProduct(product)
        });
    } catch (error) {
        console.error('Error in getProductById:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};

exports.getCategories = async (req, res) => {
    try {
        await ensureDefaultShopData();

        const categories = await prisma.productCategory.findMany({
            orderBy: [
                { sortOrder: 'asc' },
                { name: 'asc' }
            ]
        });

        res.json({
            success: true,
            data: categories
        });
    } catch (error) {
        console.error('Error in getCategories:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};
