const pool = require('../db');

async function createTicket(req, res) {
  const { firstName, lastName, workOrder, deviceDescription, jobDescription, deviceType } = req.body;

  if (!firstName || !lastName || !workOrder || !jobDescription || !deviceType) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const custName = `${firstName.trim()} ${lastName.trim()}`.trim();

  try {
    const result = await pool.query(
      `
      INSERT INTO tickets (
        ticket_number,
        cust_name,
        issue_summary,
        device_description,
        device_type
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
      `,
      [
        workOrder.trim(),
        custName,
        jobDescription.trim(),
        deviceDescription ? deviceDescription.trim() : null,
        deviceType.trim()
      ]
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
        t.device_description,
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
        t.device_description,
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
async function getBoardData(req, res) {
  try {
    const techniciansResult = await pool.query(`
      SELECT technician_id, name, email
      FROM technicians
      ORDER BY technician_id ASC
    `);

    const ticketsResult = await pool.query(`
      SELECT
        t.ticket_id,
        t.ticket_number,
        t.cust_name,
        t.issue_summary,
        t.device_type,
        t.priority_level,
        t.current_status,
        t.assigned_technician_id,
        t.sort_order,
        t.created_at,
        t.started_at,
        t.completed_at,
        tech.name AS technician_name
      FROM tickets t
      LEFT JOIN technicians tech
        ON t.assigned_technician_id = tech.technician_id
      ORDER BY
        CASE WHEN t.current_status = 'Done' THEN 1 ELSE 0 END,
        COALESCE(t.assigned_technician_id, 999999),
        t.sort_order ASC,
        t.created_at ASC
    `);

    res.json({
      technicians: techniciansResult.rows,
      tickets: ticketsResult.rows
    });
  } catch (err) {
    console.error('Board data error:', err);
    res.status(500).json({ error: 'Failed to load board data' });
  }
}

async function moveTicket(req, res) {
  const { ticketId } = req.params;
  const { assignedTechnicianId, currentStatus, sortOrder } = req.body;

  try {
    const fields = [];
    const values = [];
    let index = 1;

    if (assignedTechnicianId !== undefined) {
      fields.push(`assigned_technician_id = $${index++}`);
      values.push(assignedTechnicianId);
    }

    if (currentStatus !== undefined) {
      fields.push(`current_status = $${index++}`);
      values.push(currentStatus);
    }

    if (sortOrder !== undefined) {
      fields.push(`sort_order = $${index++}`);
      values.push(sortOrder);
    }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields provided to update' });
    }

    values.push(ticketId);

    const result = await pool.query(
      `
      UPDATE tickets
      SET ${fields.join(', ')}
      WHERE ticket_id = $${index}
      RETURNING *
      `,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    res.json({
      message: 'Ticket updated successfully',
      ticket: result.rows[0]
    });
  } catch (err) {
    console.error('Move ticket error:', err);
    res.status(500).json({ error: 'Failed to update ticket' });
  }
}

async function getTicketHistory(req, res) {
  const { ticketNumber } = req.params;

  try {
    const result = await pool.query(
      `
      SELECT
        e.event_id,
        e.event_type,
        e.old_status,
        e.new_status,
        e.event_timestamp,
        tech.name AS technician_name
      FROM ticket_events e
      JOIN tickets t
        ON t.ticket_id = e.ticket_id
      LEFT JOIN technicians tech
        ON e.technician_id = tech.technician_id
      WHERE t.ticket_number = $1
      ORDER BY e.event_timestamp ASC
      `,
      [ticketNumber]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Ticket history error:', err);
    res.status(500).json({ error: 'Failed to fetch ticket history' });
  }
}

module.exports = {
  createTicket,
  searchTickets,
  getTicketByNumber,
  getBoardData,
  moveTicket,
  getTicketHistory
};