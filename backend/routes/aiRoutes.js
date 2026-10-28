
const express = require('express');
const router = express.Router();

const {
  processNaturalLanguageTask,
  getProductivityAdvice,
} = require('../controllers/aiController');

// Kiểm tra xem controller có export đúng hàm không
console.log(
  'processNaturalLanguageTask:',
  typeof processNaturalLanguageTask
);
console.log(
  'getProductivityAdvice:',
  typeof getProductivityAdvice
);

router.post('/process-task', processNaturalLanguageTask);
router.post('/recommendation', getProductivityAdvice);

module.exports = router;
