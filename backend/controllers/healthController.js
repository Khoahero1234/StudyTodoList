// controllers/healthController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * GET /health
 * Basic server health check (không kiểm tra DB)
 */
exports.basicHealth = (req, res) => {
    res.json({
        success: true,
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: `${Math.floor(process.uptime())}s`,
    });
};

/**
 * GET /health/db
 * Kiểm tra kết nối database PostgreSQL qua Prisma
 */
exports.checkDatabase = async (req, res) => {
    const start = Date.now();
    try {
        // Chạy một raw query đơn giản để kiểm tra kết nối
        await prisma.$queryRaw`SELECT 1`;
        const latencyMs = Date.now() - start;

        return res.json({
            success: true,
            status: 'connected',
            database: 'PostgreSQL',
            latency: `${latencyMs}ms`,
            timestamp: new Date().toISOString(),
        });
    } catch (error) {
        const latencyMs = Date.now() - start;
        console.error('[DB Health Check] ❌ Database connection failed:', error.message);

        return res.status(503).json({
            success: false,
            status: 'disconnected',
            database: 'PostgreSQL',
            latency: `${latencyMs}ms`,
            error: error.message,
            hint: 'Ensure PostgreSQL is running and DATABASE_URL in .env is correct.',
            timestamp: new Date().toISOString(),
        });
    }
};

/**
 * GET /health/full
 * Kiểm tra toàn diện: server + DB + số lượng bảng chính
 */
exports.fullHealth = async (req, res) => {
    const start = Date.now();
    const report = {
        success: true,
        timestamp: new Date().toISOString(),
        uptime: `${Math.floor(process.uptime())}s`,
        server: { status: 'ok' },
        database: { status: 'unknown', latency: null, details: {} },
    };

    try {
        await prisma.$queryRaw`SELECT 1`;
        const latencyMs = Date.now() - start;

        // Đếm số record ở các bảng chính để xác nhận schema hoạt động
        const [userCount, taskCount] = await Promise.all([
            prisma.user.count(),
            prisma.task.count(),
        ]);

        report.database = {
            status: 'connected',
            latency: `${latencyMs}ms`,
            details: {
                users: userCount,
                tasks: taskCount,
            },
        };
    } catch (error) {
        report.success = false;
        report.database = {
            status: 'disconnected',
            latency: `${Date.now() - start}ms`,
            error: error.message,
            hint: 'Ensure PostgreSQL is running and DATABASE_URL in .env is correct.',
        };
        console.error('[Full Health Check] ❌ Error:', error.message);
        return res.status(503).json(report);
    }

    return res.json(report);
};

