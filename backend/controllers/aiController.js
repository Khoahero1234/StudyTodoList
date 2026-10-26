const https = require('https');

// =====================================================
// 1. GỌI CLOUDFLARE WORKERS AI
// =====================================================
function callCloudflareAI(systemPrompt, userPrompt) {
  return new Promise((resolve, reject) => {
    const accountId = process.env.CLOUDFLARE_ACCOUNT_ID?.trim();
    const apiToken = process.env.CLOUDFLARE_API_TOKEN?.trim();

    if (!accountId || !apiToken) {
      return reject(
        new Error(
          'Thiếu CLOUDFLARE_ACCOUNT_ID hoặc CLOUDFLARE_API_TOKEN trong file .env'
        )
      );
    }

    const model = '@cf/meta/llama-3.1-8b-instruct';

    const data = JSON.stringify({
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ]
    });

    const options = {
      hostname: 'api.cloudflare.com',
      path: `/client/v4/accounts/${accountId}/ai/run/${model}`,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let responseBody = '';

      res.setEncoding('utf8');

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        let parsed;

        try {
          parsed = JSON.parse(responseBody);
        } catch {
          return reject(
            new Error(
              `Cloudflare trả về dữ liệu không phải JSON (HTTP ${res.statusCode}).`
            )
          );
        }

        // Xử lý lỗi HTTP hoặc lỗi được Cloudflare báo trong JSON.
        if (
          res.statusCode < 200 ||
          res.statusCode >= 300 ||
          parsed.success === false ||
          (Array.isArray(parsed.errors) && parsed.errors.length > 0)
        ) {
          const errors = Array.isArray(parsed.errors)
            ? parsed.errors
                .map((item) => item.message || JSON.stringify(item))
                .join('; ')
            : JSON.stringify(parsed.errors || parsed);

          return reject(
            new Error(
              `Cloudflare HTTP ${res.statusCode}: ${errors}`
            )
          );
        }

        // Đọc kết quả từ nhiều định dạng phản hồi có thể gặp.
        const result = parsed.result;
        let responseText = '';

        // Định dạng Workers AI: result.response là chuỗi.
        if (
          typeof result?.response === 'string' &&
          result.response.trim()
        ) {
          responseText = result.response.trim();
        }

        // Định dạng chat completion.
        if (
          !responseText &&
          typeof result?.choices?.[0]?.message?.content === 'string'
        ) {
          responseText = result.choices[0].message.content.trim();
        }

        // Định dạng completion.
        if (
          !responseText &&
          typeof result?.choices?.[0]?.text === 'string'
        ) {
          responseText = result.choices[0].text.trim();
        }

        // Dự phòng nếu response là object.
        if (
          !responseText &&
          result?.response &&
          typeof result.response === 'object'
        ) {
          if (typeof result.response.text === 'string') {
            responseText = result.response.text.trim();
          } else if (typeof result.response.response === 'string') {
            responseText = result.response.response.trim();
          }
        }

        if (responseText) {
          return resolve(responseText);
        }

        // Chỉ ghi metadata để chẩn đoán, không ghi API token.
        console.error('Cloudflare response diagnostic:', {
          httpStatus: res.statusCode,
          success: parsed.success,
          errors: parsed.errors,
          resultType: typeof result,
          resultKeys:
            result && typeof result === 'object'
              ? Object.keys(result)
              : [],
          responseType: typeof result?.response,
          responseIsNull: result?.response === null,
          choicesCount: Array.isArray(result?.choices)
            ? result.choices.length
            : 0,
          firstChoiceKeys:
            result?.choices?.[0] &&
            typeof result.choices[0] === 'object'
              ? Object.keys(result.choices[0])
              : [],
          messageContentType:
            typeof result?.choices?.[0]?.message?.content,
          topLevelKeys: Object.keys(parsed)
        });

        return reject(
          new Error(
            'Cloudflare trả về HTTP thành công nhưng không tìm thấy nội dung văn bản trong result.response hoặc result.choices.'
          )
        );
      });
    });

    req.setTimeout(60000, () => {
      req.destroy(
        new Error('Cloudflare AI timeout sau 60 giây')
      );
    });

    req.on('error', reject);

    req.write(data);
    req.end();
  });
}


// =====================================================
// 2. PHÂN TÍCH CÂU LỆNH TỰ NHIÊN ĐỂ TẠO TASK
// =====================================================
const processNaturalLanguageTask = async (req, res) => {
  try {
    const { prompt } = req.body || {};

    if (typeof prompt !== 'string' || !prompt.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Vui lòng cung cấp nội dung prompt!'
      });
    }

    const systemInstruction = `
Bạn là trợ lý AI chuyên nghiệp cho ứng dụng Quản lý công việc
(Todo List) và Học tập.

QUY TẮC BẮT BUỘC:
1. Chỉ xử lý yêu cầu liên quan đến công việc, học tập, lập lịch
   và quản lý task.
2. Nếu người dùng hỏi ngoài phạm vi, hãy từ chối lịch sự.
3. Nếu yêu cầu chung chung, hãy đặt câu hỏi làm rõ trong description.
4. Trả về JSON thuần túy, không có markdown hoặc dấu code fence.
5. JSON phải có đúng các trường:
   - title: string
   - description: string
   - priority: "low", "medium" hoặc "high"
   - subtasks: mảng chuỗi.

Nếu từ chối yêu cầu ngoài phạm vi, vẫn trả về JSON đúng cấu trúc.
`;

    const aiResponseText = await callCloudflareAI(
      systemInstruction,
      prompt.trim()
    );

    // Loại bỏ markdown code fence nếu model trả về.
    const cleanJsonStr = aiResponseText
      .trim()
      .replace(/^```(?:json)?\s*/i, '')
      .replace(/\s*```$/, '')
      .trim();

    let result;

    try {
      result = JSON.parse(cleanJsonStr);
    } catch {
      console.error(
        'AI không trả về JSON hợp lệ:',
        cleanJsonStr.slice(0, 500)
      );

      throw new Error(
        'AI đã phản hồi nhưng nội dung không phải JSON hợp lệ. Hãy thử lại với yêu cầu rõ ràng hơn.'
      );
    }

    // Kiểm tra cấu trúc dữ liệu.
    if (
      !result ||
      typeof result.title !== 'string' ||
      typeof result.description !== 'string' ||
      !['low', 'medium', 'high'].includes(result.priority) ||
      !Array.isArray(result.subtasks) ||
      !result.subtasks.every(
        (item) => typeof item === 'string'
      )
    ) {
      throw new Error(
        'AI trả về JSON không đúng cấu trúc yêu cầu.'
      );
    }

    return res.status(200).json({
      success: true,
      data: {
        title: result.title,
        description: result.description,
        priority: result.priority,
        subtasks: result.subtasks
      }
    });
  } catch (error) {
    console.error(
      'Lỗi xử lý task AI:',
      error.message
    );

    return res.status(500).json({
      success: false,
      error: 'Đã xảy ra lỗi khi xử lý với AI.',
      details: error.message
    });
  }
};


// =====================================================
// 3. ĐƯA RA LỜI KHUYÊN VỀ NĂNG SUẤT
// =====================================================
const getProductivityAdvice = async (req, res) => {
  try {
    const { tasks, userQuery } = req.body || {};

    if (tasks !== undefined && !Array.isArray(tasks)) {
      return res.status(400).json({
        success: false,
        error: 'tasks phải là một mảng.'
      });
    }

    const taskListText =
      Array.isArray(tasks) && tasks.length > 0
        ? tasks
            .map((task) => {
              const title =
                typeof task?.title === 'string'
                  ? task.title
                  : 'Task chưa có tiêu đề';

              const priority =
                typeof task?.priority === 'string'
                  ? task.priority
                  : 'chưa xác định';

              return `- ${title} (Ưu tiên: ${priority})`;
            })
            .join('\n')
        : 'Không có task nào.';

    const systemInstruction = `
Bạn là trợ lý năng suất cho ứng dụng quản lý công việc và học tập.

Hãy phân tích danh sách task được cung cấp và đưa ra lời khuyên
thực tế, rõ ràng, dễ thực hiện.

Ưu tiên:
1. Đề xuất việc cần làm trước.
2. Chia công việc lớn thành các bước nhỏ khi phù hợp.
3. Đưa ra lịch trình hợp lý, tránh sắp xếp quá tải.
4. Trả lời bằng ngôn ngữ người dùng sử dụng.
`;

    const userPrompt = `
Danh sách task:
${taskListText}

Câu hỏi:
${
  typeof userQuery === 'string' && userQuery.trim()
    ? userQuery.trim()
    : 'Hôm nay tôi nên làm gì?'
}
`;

    const recommendation = await callCloudflareAI(
      systemInstruction,
      userPrompt
    );

    return res.status(200).json({
      success: true,
      recommendation
    });
  } catch (error) {
    console.error(
      'Lỗi productivity recommendation:',
      error.message
    );

    return res.status(500).json({
      success: false,
      error: 'Không thể tạo lời khuyên.',
      details: error.message
    });
  }
};


// =====================================================
// 4. EXPORT CÁC HÀM CHO aiRoutes.js
// =====================================================
module.exports = {
  processNaturalLanguageTask,
  getProductivityAdvice
};