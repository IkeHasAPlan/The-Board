const pool = require('../db');

async function createTicket(req, res) {
  const { firstName, lastName, workOrder, deviceDescription, jobDescription, deviceType } = req.body;

  if (!firstName || !lastName || !workOrder || !jobDescription || !deviceType) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const custName = `${firstName.trim()} ${lastName.trim()}`.trim();
  const issueSummary = deviceDescription && deviceDescription.trim()
    ? `${deviceDescription.trim()} - ${jobDescription.trim()}`
    : jobDescription.trim();

  try {
    const result = await pool.query(
      `
      INSERT INTO tickets (
        ticket_number,
        cust_name,
        issue_summary,
        device_type
      )
      VALUES ($1, $2, $3, $4)
      RETURNING *
      `,
      [workOrder.trim(), custName, issueSummary, deviceType.trim()]
    );

    res.status(201).json({
      message: 'Ticket created successfully',
      ticket: result.rows[0]
    });
  } catch (err) {
    console.error('Create ticket error:', err);

    if (err.code === '23505') {
      return res.status(400).json({ error: 'That work order number already exists.' });
    }

    res.status(500).json({ error: 'Failed to create ticket' });
  }
}

async function searchTickets(req, res) {
  const search = req.query.q || '';

  try {
    const result = await pool.query(
      `
      SELECT 
        t.ticket_id,
        t.ticket_number,
        t.cust_name,
        t.issue_summary,
        t.device_type,
        t.priority_level,
        t.current_status,
        t.created_at,
        t.started_at,
        t.completed_at,
        tech.name AS technician_name
      FROM tickets t
      LEFT JOIN technicians tech
        ON t.assigned_technician_id = tech.technician_id
      WHERE
        t.ticket_number ILIKE $1 OR
        t.cust_name ILIKE $1 OR
        t.issue_summary ILIKE $1 OR
        t.device_type ILIKE $1
      ORDER BY t.updated_at DESC
      LIMIT 25
      `,
      [`%${search}%`]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ error: 'Failed to search tickets' });
  }
}

async function getTicketByNumber(req, res) {
  const { ticketNumber } = req.params;

  try {
    const result = await pool.query(
      `
      SELECT 
        t.ticket_id,
        t.ticket_number,
        t.cust_name,
        t.issue_summary,
        t.device_type,
        t.priority_level,
        t.current_status,
        t.created_at,
        t.started_at,
        t.completed_at,
        tech.name AS technician_name
      FROM tickets t
      LEFT JOIN technicians tech
        ON t.assigned_technician_id = tech.technician_id
      WHERE t.ticket_number = $1
      `,
      [ticketNumber]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Ticket lookup error:', err);
    res.status(500).json({ error: 'Failed to fetch ticket' });
  }
}

module.exports = {
  createTicket,
  searchTickets,
  getTicketByNumber,
};