const express = require('express');
const cors = require('cors');
const path = require('path');
const ticketRoutes = require('./routes/TicketRoutes');
const reportRoutes = require('./routes/ReportRoutes');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

app.use(express.static(path.join(__dirname, 'client')));
app.use(express.static(path.join(__dirname, 'admin_create_token')));

app.post('/login', (req, res) => {
  const { username, password } = req.body;

  const users = [
    { username: 'admin', password: '123', role: 'admin', displayName: 'Administrator' },
    { username: 'isaac', password: '123', role: 'employee', displayName: 'Isaac' },
    { username: 'employee', password: '123', role: 'employee', displayName: 'Employee' }
  ];

  const user = users.find(
    (u) => u.username === username && u.password === password
  );

  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  res.json({
    success: true,
    role: user.role,
    displayName: user.displayName
  });
});

app.use('/board', express.static(path.join(__dirname, 'client', 'board-frontend', 'dist')));

app.get('/board', (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'board-frontend', 'dist', 'index.html'));
});

app.use('/tickets', ticketRoutes);
app.use('/technicians', technicianRoutes);
app.use('/reports', reportRoutes);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

const technicianRoutes = require('./routes/TechnicianRoutes');
app.use('/technicians', technicianRoutes);

