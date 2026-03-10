const express = require('express');
const router = express.Router();
const { createTicket } = require('../controllers/TicketController');

router.post('/', createTicket);

module.exports = router;
