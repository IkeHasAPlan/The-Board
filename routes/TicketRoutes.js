const express = require('express');
const router = express.Router();
const {
  createTicket,
  searchTickets,
  getTicketByNumber
} = require('../controllers/TicketController');



router.post('/', createTicket);
router.get('/search', searchTickets);
router.get('/:ticketNumber', getTicketByNumber);

module.exports = router;