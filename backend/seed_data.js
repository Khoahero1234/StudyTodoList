// backend/seed_data.js
require('dotenv').config();

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Bắt đầu khởi tạo dữ liệu mẫu (Shop, Tasks, Rewards, Wallet)...');

    // 1. Seed Product Categories & Shop Products
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
            update: { description: cat.description, sortOrder: cat.sortOrder },
            create: cat
        });
        categoryMap[cat.name] = created.id;
        console.log(`+ Danh mục Shop sẵn sàng: "${cat.name}"`);
    }

    const defaultProducts = [
        {
            name: 'Bùa Hộ Mệnh Streak (Streak Freeze)',
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
            console.log(`+ Đã tạo sản phẩm Shop: "${prod.name}" (${prod.price} Token)`);
        }
    }

    // 2. Seed Daily Rewards
    const sampleRewards = [
        {
            name: 'Thưởng Điểm Danh Ngày 1 🌟',
            description: 'Đăng nhập ngày đầu tiên trong chuỗi',
            type: 'TOKEN',
            value: 20,
            streakDay: 1,
            isActive: true
        },
        {
            name: 'Thưởng Chuỗi 3 Ngày 🔥',
            description: 'Giữ vững phong độ 3 ngày liên tục',
            type: 'TOKEN',
            value: 50,
            streakDay: 3,
            isActive: true
        },
        {
            name: 'Thưởng Chuỗi 5 Ngày ⭐',
            description: 'Duy trì học tập và làm việc 5 ngày liên tục',
            type: 'TOKEN',
            value: 100,
            streakDay: 5,
            isActive: true
        },
        {
            name: 'Thưởng Chuỗi 7 Ngày Siêu Cấp 👑',
            description: 'Đạt mốc 1 tuần học tập liên tục!',
            type: 'TOKEN',
            value: 200,
            streakDay: 7,
            isActive: true
        }
    ];

    for (const rewardData of sampleRewards) {
        const existingReward = await prisma.reward.findFirst({
            where: { name: rewardData.name }
        });

        if (!existingReward) {
            await prisma.reward.create({ data: rewardData });
            console.log(`+ Đã tạo mốc thưởng: "${rewardData.name}"`);
        }
    }

    // 3. Tạo tài khoản Học viên mẫu nếu DB chưa có user
    let users = await prisma.user.findMany();
    if (users.length === 0) {
        const hashedPassword = await bcrypt.hash('123456', 10);
        const demoUser = await prisma.user.create({
            data: {
                email: 'student@studytodo.com',
                username: 'student',
                displayName: 'Học Viên Chăm Chỉ',
                password: hashedPassword,
                role: 'CUSTOMER'
            }
        });
        users = [demoUser];
        console.log('👤 Đã tạo tài khoản mẫu: student@studytodo.com / Mật khẩu: 12345678');
    }

    for (const user of users) {
        let wallet = await prisma.wallet.findUnique({ where: { userId: user.id } });
        if (!wallet) {
            wallet = await prisma.wallet.create({
                data: { userId: user.id, balance: 500 }
            });
            await prisma.tokenTransaction.create({
                data: {
                    userId: user.id,
                    walletId: wallet.id,
                    type: 'BONUS',
                    amount: 500,
                    balanceAfter: 500,
                    description: 'Token khởi tạo trải nghiệm Cửa hàng'
                }
            });
            console.log(`💰 Đã tạo ví 500 Token cho ${user.email}`);
        } else if (wallet.balance < 100) {
            const added = 300;
            const newBal = wallet.balance + added;
            await prisma.wallet.update({
                where: { id: wallet.id },
                data: { balance: newBal }
            });
            await prisma.tokenTransaction.create({
                data: {
                    userId: user.id,
                    walletId: wallet.id,
                    type: 'BONUS',
                    amount: added,
                    balanceAfter: newBal,
                    description: 'Bổ sung Token test tính năng mua hàng Shop'
                }
            });
            console.log(`💰 Đã cộng thêm ${added} Token cho ${user.email} (Số dư mới: ${newBal} Token)`);
        }

        let streak = await prisma.loginStreak.findUnique({ where: { userId: user.id } });
        if (!streak) {
            await prisma.loginStreak.create({
                data: {
                    userId: user.id,
                    currentStreak: 3,
                    longestStreak: 5,
                    lastLoginDate: new Date()
                }
            });
        }

        let category = await prisma.category.findFirst({ where: { userId: user.id } });
        if (!category) {
            category = await prisma.category.create({
                data: {
                    name: 'Học tập & Lập trình',
                    color: '#6C63FF',
                    icon: 'school',
                    userId: user.id
                }
            });
        }

        const sampleTasks = [
            {
                title: 'Hoàn thành bài tập Flutter PRM393',
                description: 'Kiểm tra tích hợp Riverpod và GoRouter cho module mới',
                priority: 'URGENT',
                status: 'PENDING',
                dueDate: new Date(),
                estimatedMinutes: 45,
                tokenReward: 25,
                xpReward: 30,
                tags: ['flutter', 'prm393', 'urgent'],
                categoryId: category.id,
                userId: user.id
            },
            {
                title: 'Review kiến thức Node.js & Prisma ORM',
                description: 'Đọc tài liệu về Prisma Transactions và Middleware',
                priority: 'HIGH',
                status: 'PENDING',
                dueDate: new Date(Date.now() + 86400000),
                estimatedMinutes: 30,
                tokenReward: 15,
                xpReward: 20,
                tags: ['nodejs', 'backend'],
                categoryId: category.id,
                userId: user.id
            }
        ];

        for (const taskData of sampleTasks) {
            const existingTask = await prisma.task.findFirst({
                where: { userId: user.id, title: taskData.title }
            });

            if (!existingTask) {
                await prisma.task.create({ data: taskData });
            }
        }
    }

    console.log('✅ Seeding hoàn tất thành công!');
}

main()
    .catch((e) => {
        console.error('❌ Seeding error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
