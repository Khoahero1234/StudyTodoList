// backend/tests/wallet.test.js

const walletService = require('../services/walletService');

// Mock Prisma Client
jest.mock('@prisma/client', () => {
    const mPrismaClient = {
        $transaction: jest.fn((callback) => callback({
            wallet: {
                findUnique: jest.fn().mockResolvedValue({ id: 'wallet_1', balance: 100 }),
                update: jest.fn().mockResolvedValue({ id: 'wallet_1', balance: 150 })
            },
            user: {
                update: jest.fn().mockResolvedValue({ id: 'user_1', tokenBalance: 150 })
            },
            tokenTransaction: {
                create: jest.fn().mockResolvedValue({ id: 'tx_1', amount: 50, type: 'EARNED' })
            }
        }))
    };
    return {
        PrismaClient: jest.fn(() => mPrismaClient)
    };
});

describe('Wallet Service - adjustBalance', () => {
    test('should successfully adjust wallet balance (positive amount)', async () => {
        const result = await walletService.adjustBalance('user_1', 50, 'EARNED', 'Test bonus', 'ref_1');

        expect(result).toBeDefined();
        expect(result.wallet.balance).toBe(150);
        expect(result.transaction.amount).toBe(50);
        expect(result.transaction.type).toBe('EARNED');
    });

    test('should throw error when balance goes below zero', async () => {
        const { PrismaClient } = require('@prisma/client');
        const prismaInstance = new PrismaClient();
        prismaInstance.$transaction.mockImplementationOnce(async (callback) => {
            return await callback({
                wallet: {
                    findUnique: jest.fn().mockResolvedValue({ id: 'wallet_1', balance: 20 }),
                    update: jest.fn()
                },
                user: { update: jest.fn() },
                tokenTransaction: { create: jest.fn() }
            });
        });

        await expect(
            walletService.adjustBalance('user_1', -50, 'SPENT', 'Overspend', 'ref_2')
        ).rejects.toThrow('Insufficient token balance');
    });
});
