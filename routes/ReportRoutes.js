const express = require('express');
const router = express.Router();

const {
  getReportSummary,
  getTechnicianPerformance
} = require('../controllers/ReportController');

router.get('/summary', getReportSummary);
router.get('/technicians', getTechnicianPerformance);

module.exports = router;
