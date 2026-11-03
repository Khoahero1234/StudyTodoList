// backend/dtos/productDto.js

function formatProduct(product) {
    if (!product) return null;
    return {
        id: product.id,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        rarity: product.rarity,
        stock: product.stock,
        discountPct: product.discountPct,
        isAvailable: product.isAvailable,
        premiumOnly: product.premiumOnly,
        categoryId: product.categoryId,
        category: product.category ? {
            id: product.category.id,
            name: product.category.name
        } : null,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt
    };
}

function formatProductList(products) {
    if (!Array.isArray(products)) return [];
    return products.map(formatProduct);
}

module.exports = {
    formatProduct,
    formatProductList
};
