const express = require('express');
const router = express.Router();

const {
  getTechnicians,
  createTechnician,
  updateTechnician,
  deactivateTechnician
} = require('../controllers/TechnicianController');

router.get('/', getTechnicians);
router.post('/', createTechnician);
router.patch('/:id', updateTechnician);
router.patch('/:id/deactivate', deactivateTechnician);

module.exports = router;
