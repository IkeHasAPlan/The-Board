const express = require('express');
const cors = require('cors');
const path = require('path');
const ticketRoutes = require('./routes/TicketRoutes');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

app.use(express.static(path.join(__dirname,'client')));
app.use(express.static(path.join(__dirname,'admin_create_token')));

app.post("/login",(req,res)=>{
  const {username,password}=req.body;

  const ADMIN_USER="admin";
  const ADMIN_PASS="123";

  if(username===ADMIN_USER && password===ADMIN_PASS){
    res.json({success:true});
  }else{
    res.status(401).json({error:"Invalid credentials"});
  }
});

app.use('/board', express.static(path.join(__dirname, 'client', 'board-frontend', 'dist')));

app.get('/board', (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'board-frontend', 'dist', 'index.html'));
});

app.use('/tickets', ticketRoutes);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});