// backend/services/petService.js

exports.gainXp = async (userId, amount) => {
    console.log(`[petService] User ${userId} gained ${amount} XP`);
    return { success: true, userId, amount };
};
