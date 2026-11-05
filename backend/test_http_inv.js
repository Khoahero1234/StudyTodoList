require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const jwt = require('jsonwebtoken');
const http = require('http');

function get(url, token) {
    return new Promise((resolve, reject) => {
        const u = new URL(url);
        const req = http.request({
            hostname: u.hostname,
            port: u.port,
            path: u.pathname,
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        }, res => {
            let resData = '';
            res.on('data', chunk => resData += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(resData) }));
        });
        req.on('error', reject);
        req.end();
    });
}

async function run() {
    const user = await prisma.user.findFirst({ where: { username: 'lmtruong' } });
    const token = jwt.sign(
        { id: user.id, role: user.role },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '7d' }
    );
    console.log('User:', user.username, 'ID:', user.id);

    const invRes = await get('http://localhost:3000/api/v1/orders/inventory', token);
    console.log('Inventory API status:', invRes.status);
    console.log('Inventory API body:', JSON.stringify(invRes.body, null, 2));

    const orderRes = await get('http://localhost:3000/api/v1/orders', token);
    console.log('Orders API status:', orderRes.status);
    console.log('Orders API count:', orderRes.body.data.orders.length);
}

run().finally(() => prisma.$disconnect());
