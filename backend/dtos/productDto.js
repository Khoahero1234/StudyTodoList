// backend/dtos/productDto.js

function formatProduct(product) {
    if (!product) return null;
    const discountPct = product.discountPct || 0;
    const discountedPrice = discountPct > 0
        ? Math.floor((product.price * (100 - discountPct)) / 100)
        : product.price;

    return {
        id: product.id,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        discountedPrice,
        rarity: product.rarity,
        stock: product.stock,
        discountPct,
        isAvailable: product.isAvailable,
        premiumOnly: Boolean(product.isPremiumOnly),
        isPremiumOnly: Boolean(product.isPremiumOnly),
        categoryId: product.categoryId,
        category: product.category ? {
            id: product.category.id,
            name: product.category.name,
            description: product.category.description,
            iconUrl: product.category.iconUrl
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
