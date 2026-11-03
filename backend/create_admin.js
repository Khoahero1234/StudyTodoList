// backend/create_admin.js
// Script tạo tài khoản Admin

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function createAdmin() {
    const email       = 'admin@studytodo.com'; // ← Đổi email tại đây
    const password    = 'Admin@123456';        // ← Đổi password tại đây
    const username    = 'admin';               // ← Phải unique
    const displayName = 'Admin';

    // Kiểm tra đã tồn tại chưa
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
        console.log(`⚠️  User với email "${email}" đã tồn tại (role: ${existing.role})`);

        // Nếu đã có thì nâng lên ADMIN
        if (existing.role !== 'ADMIN') {
            await prisma.user.update({
                where: { email },
                data: { role: 'ADMIN' }
            });
            console.log('✅ Đã cập nhật role thành ADMIN!');
        } else {
            console.log('✅ Tài khoản đã là ADMIN rồi.');
        }
        return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const admin = await prisma.user.create({
        data: {
            email,
            username,
            displayName,
            password: hashedPassword,
            role: 'ADMIN',
        }
    });

    console.log('✅ Tạo tài khoản Admin thành công!');
    console.log(`   Email   : ${admin.email}`);
    console.log(`   Role    : ${admin.role}`);
    console.log(`   Password: ${password}  (lưu lại!)`);
}

createAdmin()
    .catch(e => {
        console.error('❌ Lỗi:', e.message);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());
