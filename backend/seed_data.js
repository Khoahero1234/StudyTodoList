// backend/seed_data.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Starting database seeding for Tasks, Rewards, and Categories...');

    // 1. Find all users or default user
    const users = await prisma.user.findMany();
    if (users.length === 0) {
        console.log('⚠️ No users found in database. Please register/login a user first!');
        return;
    }

    console.log(`Found ${users.length} user(s) in database.`);

    for (const user of users) {
        // Ensure user has Wallet
        let wallet = await prisma.wallet.findUnique({ where: { userId: user.id } });
        if (!wallet) {
            wallet = await prisma.wallet.create({
                data: { userId: user.id, balance: user.tokenBalance || 50 }
            });
            console.log(`Created wallet for user ${user.email}`);
        }

        // Ensure user has LoginStreak
        let streak = await prisma.loginStreak.findUnique({ where: { userId: user.id } });
        if (!streak) {
            streak = await prisma.loginStreak.create({
                data: {
                    userId: user.id,
                    currentStreak: 3,
                    longestStreak: 5,
                    lastLoginDate: new Date()
                }
            });
            await prisma.user.update({
                where: { id: user.id },
                data: { currentStreak: 3 }
            });
            console.log(`Created login streak for user ${user.email}`);
        }

        // Create sample Categories for user
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
            await prisma.category.create({
                data: {
                    name: 'Sức khỏe & Thể thao',
                    color: '#00D4FF',
                    icon: 'fitness_center',
                    userId: user.id
                }
            });
        }

        // Create sample tasks
        const sampleTasks = [
            {
                title: 'Hoàn thành bài tập Flutter PRM393',
                description: 'Kiểm tra tích hợp Riverpod và GoRouter cho module mới',
                priority: 'urgent',
                status: 'pending',
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
                priority: 'high',
                status: 'pending',
                dueDate: new Date(Date.now() + 86400000), // Tomorrow
                estimatedMinutes: 30,
                tokenReward: 15,
                xpReward: 20,
                tags: ['nodejs', 'backend'],
                categoryId: category.id,
                userId: user.id
            },
            {
                title: 'Đọc 15 trang sách Lập trình sạch (Clean Code)',
                description: 'Tóm tắt các nguyên tắc refactoring code',
                priority: 'medium',
                status: 'pending',
                dueDate: new Date(),
                estimatedMinutes: 20,
                tokenReward: 10,
                xpReward: 15,
                tags: ['reading', 'cleancode'],
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
                console.log(`+ Created task "${taskData.title}" (+${taskData.tokenReward} Tokens) for ${user.email}`);
            }
        }
    }

    // 2. Seed Daily Rewards
    const sampleRewards = [
        {
            title: 'Thưởng Điểm Danh Ngày 1 🌟',
            description: 'Đăng nhập ngày đầu tiên trong chuỗi',
            type: 'token',
            amount: 20,
            requiredStreak: 1,
            isActive: true
        },
        {
            title: 'Thưởng Chuỗi 3 Ngày 🔥',
            description: 'Giữ vững phong độ 3 ngày liên tục',
            type: 'token',
            amount: 50,
            requiredStreak: 3,
            isActive: true
        },
        {
            title: 'Thưởng Chuỗi 5 Ngày ⭐',
            description: 'Duy trì học tập và làm việc 5 ngày liên tục',
            type: 'token',
            amount: 100,
            requiredStreak: 5,
            isActive: true
        },
        {
            title: 'Thưởng Chuỗi 7 Ngày Siêu Cấp 👑',
            description: 'Đạt mốc 1 tuần học tập liên tục!',
            type: 'token',
            amount: 200,
            requiredStreak: 7,
            isActive: true
        }
    ];

    for (const rewardData of sampleRewards) {
        const existingReward = await prisma.reward.findFirst({
            where: { title: rewardData.title }
        });

        if (!existingReward) {
            await prisma.reward.create({ data: rewardData });
            console.log(`+ Created Reward "${rewardData.title}"`);
        }
    }

    console.log('✅ Seeding completed successfully!');
}

main()
    .catch((e) => {
        console.error('❌ Seeding error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
