const missionService = require('../services/missionService');

exports.getDailyMissions = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await missionService.evaluateAndAutoRewardMissions(userId);

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('getDailyMissions error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi khi lấy danh sách nhiệm vụ tự động'
        });
    }
};

exports.trackMissionActivity = async (req, res) => {
    try {
        const userId = req.user.id;
        const { type, value } = req.body;

        if (!type) {
            return res.status(400).json({
                success: false,
                message: 'Thiếu loại hoạt động (type)'
            });
        }

        const result = await missionService.trackActivity(userId, { type, value });

        res.json({
            success: true,
            data: result,
            message: result.totalTokensAwarded > 0
                ? `Tự động hoàn thành & cộng +${result.totalTokensAwarded} Token vào ví!`
                : 'Đã cập nhật tiến độ nhiệm vụ tự động!'
        });
    } catch (error) {
        console.error('trackMissionActivity error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi khi cập nhật tiến độ nhiệm vụ tự động'
        });
    }
};

exports.generateSampleTasks = async (req, res) => {
    try {
        const userId = req.user.id;
        const createdTasks = await missionService.ensureDailyStudyTasks(userId, true);
        const evaluation = await missionService.evaluateAndAutoRewardMissions(userId);

        res.status(201).json({
            success: true,
            data: {
                createdTasks,
                evaluation
            },
            message: `Đã tạo ${createdTasks.length} công việc học tập mới cho hôm nay!`
        });
    } catch (error) {
        console.error('generateSampleTasks error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi khi tạo công việc mẫu'
        });
    }
};
