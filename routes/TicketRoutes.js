const express = require('express');
const router = express.Router();

const {
  createTicket,
  searchTickets,
  getTicketByNumber,
  getBoardData,
  moveTicket,
  getTicketHistory,
  updateTicketDetails,
  deleteTicket
} = require('../controllers/TicketController');

router.post('/', createTicket);
router.get('/search', searchTickets);
router.get('/board-data', getBoardData);
router.patch('/:ticketId/move', moveTicket);
router.delete('/:ticketId', deleteTicket);
router.patch('/:ticketNumber/details', updateTicketDetails);
router.get('/:ticketNumber/history', getTicketHistory);
router.get('/:ticketNumber', getTicketByNumber);

module.exports = router;