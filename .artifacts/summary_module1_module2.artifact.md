# 📋 Báo cáo Phân tích, Tái cấu trúc & Hoàn thiện Dự án: StudyTodoList (EdTech Platform)

Tài liệu này tổng hợp toàn bộ các thay đổi, phân tích kiến trúc và bổ sung mã nguồn của toàn dự án **StudyTodoList**, bao gồm: **Module 1 (Wallet & Token)**, **Module 2 (Shop & Inventory)**, **Hệ thống Nhiệm vụ Học tập Tự động (Automated Study Missions)** thay thế Thú ảo, và **Module 6 (Infrastructure, Security & QA)**.

---

## ⚠️ 1. Thông báo lỗi API LLM (`RESOURCE_EXHAUSTED`)
- **Nguyên nhân**: Thông báo `Model query failed: RESOURCE_EXHAUSTED: You have exhausted your capacity on this model...` xuất phát từ nhà cung cấp dịch vụ AI (Google Gemini API), cho biết hạn mức (quota) hoặc số lượng yêu cầu (rate limit) đã vượt quá giới hạn trong khung thời gian hiện tại.
- **Tính chất**: Đây không phải là lỗi trong mã nguồn Node.js hay Flutter của ứng dụng. Hệ thống sẽ tự động khôi phục sau khi hết thời gian giới hạn từ phía nhà cung cấp.

---

## 🐾 2. Tái cấu trúc: Loại bỏ Thú ảo & Xây dựng Nhiệm vụ Học tập Tự động (Automated Study Missions)

### A. Loại bỏ hoàn toàn Thú ảo (Virtual Pet)
- Đã xóa bỏ toàn bộ các tham chiếu, route, controller và màn hình giao diện liên quan đến hệ thống Virtual Pet (`pet_screen.dart`, endpoint `/pet/*`), giúp ứng dụng tập trung hoàn toàn vào nền tảng quản lý học tập và nâng cao năng suất (EdTech).

### B. Quản lý Dữ liệu & Backend (Node.js / Express / Prisma)
1. **Prisma Schema (`backend/prisma/schema.prisma`)**:
   - Thiết kế các model tiêu chuẩn EdTech: `MissionTemplate` (quản lý mẫu nhiệm vụ do Admin tạo) và `UserMissionProgress` (theo dõi tiến độ cá nhân của từng user theo ngày).
2. **Tracking & Mission Controller (`backend/controllers/missionController.js`)**:
   - `GET /api/missions/daily`: Tự động khởi tạo bộ nhiệm vụ mặc định trong ngày (Học trực tuyến 120 phút, Phiên Pomodoro 4 lần, Làm bài tập 60 phút) và trả về tiến độ thực tế.
   - `POST /api/missions/track` (Automated Tracking): Ghi nhận ngầm tiến độ hoạt động học tập. Khi `currentProgress >= targetValue`, hệ thống tự động hoàn thành nhiệm vụ (`isCompleted = true`) và **bắt buộc gọi `walletService.adjustBalance`** để cộng Token thưởng vào ví user thông qua Prisma Transaction an toàn.
   - `POST /api/admin/missions`: Endpoint bảo mật dành riêng cho Admin để tạo mới các mẫu nhiệm vụ.

### C. Giao diện & Frontend (Flutter / Riverpod)
1. **Data Model & Remote DataSource (`mission_model.dart`, `missions_remote_datasource.dart`)**:
   - Ánh xạ JSON dữ liệu nhiệm vụ tự động và hàm tính toán phần trăm tiến độ `progressPercentage`.
2. **Mission Provider (`lib/features/missions/providers/mission_provider.dart`)**:
   - Quản lý trạng thái danh sách nhiệm vụ hàng ngày, xử lý tracking ngầm và tự động gọi `refreshWallet()` khi nhận thưởng token.
3. **Mission Screen UI (`mission_screen.dart`)**:
   - **Tuyệt đối không sử dụng checkbox hay nút bấm thủ công** cho người dùng. Thay vào đó, sử dụng thanh tiến trình trực quan (`LinearProgressIndicator`) hiển thị rõ ràng tiến độ (ví dụ: 45 / 120 phút). Khi đạt 100%, hiển thị nhãn **"✓ Đã hoàn thành"**.
   - **Mô phỏng Ghi nhận Tiến độ (Mock Tracking Trigger)**: Cung cấp các nút test nhanh (`+1 Pomodoro`, `+30 phút Online`, `+20 phút Bài tập`) giúp kiểm tra ngay lập tức luồng tự động tăng thanh tiến độ và cộng Token vào ví.

---

## 🛡️ 3. Module 6: Infrastructure, Security & Quality Assurance

### A. Security & Error Handling (Backend)
1. **Global Error Handler (`backend/middleware/errorHandler.js`)**:
   - Middleware xử lý lỗi toàn cục, tự động log lỗi và trả về JSON chuẩn định dạng: `{ success: false, data: null, error: message }`.
2. **Admin RBAC Verification (`backend/middleware/authMiddleware.js`)**:
   - Hàm `verifyAdmin` kiểm tra `req.user.role === 'ADMIN' || req.user.isAdmin === true` để bảo vệ các route quản trị.
3. **Validation Input (`backend/middleware/validation.js`)**:
   - Tích hợp `express-validator` cho phân trang (`validatePagination`) và mua hàng (`validatePurchase`, đảm bảo quantity > 0).

### B. Testing & CI/CD (Backend)
1. **Package Scripts & Jest (`backend/package.json`, `backend/tests/wallet.test.js`)**:
   - Cấu hình Jest unit test mẫu cho hàm `walletService.adjustBalance` với Prisma Client được mock hoàn chỉnh.
   - Bổ sung scripts chuẩn: `"test": "jest --detectOpenHandles"`, `"lint": "eslint ."`, `"migrate:deploy": "npx prisma migrate deploy"`.

### C. Documentation
1. **API Documentation (`backend/docs/api.md`)**:
   - Tài liệu chuẩn OpenAPI 3.0 mô tả chi tiết các endpoint trọng yếu (`GET /api/wallet` và `POST /api/orders`) kèm Payload và Response JSON mẫu.

### D. Frontend API Client Standardization
1. **API Client Wrapper (`lib/core/network/api_client.dart`)**:
   - Lớp bọc HTTP request tự động parse JSON response, kiểm tra `success == false` và `throw Exception` kèm thông điệp lỗi từ backend để giao diện Flutter dễ dàng bắt lỗi và hiển thị SnackBar thông báo.
