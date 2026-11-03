// backend/controllers/shopController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const productDto = require('../dtos/productDto');

exports.getProducts = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const { search, categoryId, rarity, premiumOnly } = req.query;

        const where = {
            isAvailable: true
        };

        if (search) {
            where.name = { contains: search, mode: 'insensitive' };
        }
        if (categoryId) {
            where.categoryId = categoryId;
        }
        if (rarity) {
            where.rarity = rarity;
        }
        if (premiumOnly !== undefined) {
            where.premiumOnly = premiumOnly === 'true' || premiumOnly === true;
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
                    totalPages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Error in getProducts:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getProductById = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await prisma.product.findUnique({
            where: { id },
            include: { category: true }
        });

        if (!product) {
            return res.status(404).json({ success: false, error: 'Product not found' });
        }

        res.json({
            success: true,
            data: productDto.formatProduct(product)
        });
    } catch (error) {
        console.error('Error in getProductById:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getCategories = async (req, res) => {
    try {
        const categories = await prisma.productCategory.findMany({
            orderBy: { name: 'asc' }
        });

        res.json({
            success: true,
            data: categories
        });
    } catch (error) {
        console.error('Error in getCategories:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};
