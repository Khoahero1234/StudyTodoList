const jwt = require('jsonwebtoken');
const http = require('http');

const userId = 'c6fb62f9-c558-4918-b983-e04298f2f35f';
const secret = 'super_secret_jwt_key_for_dev';
const token = jwt.sign({ id: userId, email: 'user@gmail.com', role: 'USER' }, secret, { expiresIn: '7d' });

function request(path) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: '127.0.0.1',
      port: 3000,
      path: '/api/v1' + path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({ status: res.statusCode, data: JSON.parse(data) });
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function test() {
  const inv = await request('/orders/inventory');
  console.log('GET /orders/inventory:', JSON.stringify(inv, null, 2));

  const orders = await request('/orders');
  console.log('GET /orders:', JSON.stringify(orders, null, 2));
}

test();
