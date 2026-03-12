const express = require('express');
const router = express.Router();
const {
  createTicket,
  searchTickets,
  getTicketByNumber,
  getBoardData,
  moveTicket
} = require('../controllers/TicketController');


router.post('/', createTicket);
router.get('/search', searchTickets);
router.get('/board-data', getBoardData);
router.patch('/:ticketId/move', moveTicket);
router.get('/:ticketNumber', getTicketByNumber);

module.exports = router;