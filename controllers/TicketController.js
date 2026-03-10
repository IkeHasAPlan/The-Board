function createTicket(req, res) {
  const { firstName, lastName, workOrder, deviceDescription, jobDescription, deviceType } = req.body;

  if (!firstName || !lastName || !workOrder || !jobDescription || !deviceType) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // TODO: save to database (hand off to backend/DB team)
  console.log('New ticket received:', req.body);

  res.status(201).json({
    message: 'Ticket received',
    ticket: { firstName, lastName, workOrder, deviceDescription, jobDescription, deviceType }
  });
}

module.exports = { createTicket };
