const express = require('express');
const cors = require('cors');
const path = require('path');
const ticketRoutes = require('./routes/TicketRoutes');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'client')));

app.get('/', (req, res) => {
  res.send('Backend is running');
});

app.use('/tickets', ticketRoutes);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});