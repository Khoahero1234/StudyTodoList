-- backend/seed_wallet.sql
-- Script tự động thêm Wallet, TokenTransaction và đồng bộ User.tokenBalance theo email

DO $$
DECLARE
    v_user_id TEXT;
    v_wallet_id TEXT;
BEGIN
    -- Lấy userId của bạn dựa vào email đăng nhập
    SELECT id INTO v_user_id FROM "User" WHERE email = 'truongkevin08@gmail.com';

    IF v_user_id IS NOT NULL THEN
        -- 1. Cập nhật tokenBalance trên bảng User thành 150
        UPDATE "User" SET "tokenBalance" = 150, "updatedAt" = NOW() WHERE id = v_user_id;

        -- 2. Kiểm tra xem user đã có Wallet chưa, nếu chưa thì tạo mới với balance = 150
        SELECT id INTO v_wallet_id FROM "Wallet" WHERE "userId" = v_user_id;

        IF v_wallet_id IS NULL THEN
            v_wallet_id := gen_random_uuid()::text;
            INSERT INTO "Wallet" (id, "userId", balance, "createdAt", "updatedAt")
            VALUES (v_wallet_id, v_user_id, 150, NOW(), NOW());
            RAISE NOTICE 'Đã tạo Wallet mới với ID: %', v_wallet_id;
        ELSE
            -- Nếu đã có ví, cập nhật số dư thành 150
            UPDATE "Wallet" SET balance = 150, "updatedAt" = NOW() WHERE id = v_wallet_id;
            RAISE NOTICE 'Wallet đã tồn tại, đã cập nhật số dư thành 150.';
        END IF;

        -- 3. Xóa các giao dịch cũ để làm sạch lịch sử test
        DELETE FROM "TokenTransaction" WHERE "walletId" = v_wallet_id;

        -- 4. Thêm lịch sử giao dịch mẫu 1 (Cộng tiền thưởng)
        INSERT INTO "TokenTransaction" (id, "walletId", amount, type, description, "createdAt")
        VALUES (gen_random_uuid()::text, v_wallet_id, 100, 'REWARD', 'Thưởng hoàn thành nhiệm vụ đặc biệt', NOW() - INTERVAL '2 hour');

        -- 5. Thêm lịch sử giao dịch mẫu 2 (Cộng tiền bonus)
        INSERT INTO "TokenTransaction" (id, "walletId", amount, type, description, "createdAt")
        VALUES (gen_random_uuid()::text, v_wallet_id, 50, 'BONUS', 'Thưởng đăng nhập hàng ngày', NOW());

        RAISE NOTICE 'Đã đồng bộ User tokenBalance, Wallet và Lịch sử giao dịch thành công!';
    ELSE
        RAISE NOTICE 'Không tìm thấy user với email này trong database! Hãy kiểm tra lại email.';
    END IF;
END $$;
