const pool = require('../db');

async function createTicket(req, res) {
const {
  firstName,
  lastName,
  workOrder,
  ticketNumber,
  deviceDescription,
  jobDescription,
  deviceType,
  warranty
} = req.body;

const workOrderValue = workOrder || ticketNumber;

if (!firstName || !lastName || !workOrderValue || !jobDescription || !deviceType) {
  return res.status(400).json({ error: 'Missing required fields' });
}

  const custName = `${firstName.trim()} ${lastName.trim()}`.trim();

  var priority_to_set = "Urgent";
  var warranty_to_set = (warranty || false);
  if (!warranty) {
    priority_to_set = "Normal";
  }

  try {
    const result = await pool.query(
      `
      INSERT INTO tickets (
        ticket_number,
        cust_name,
        issue_summary,
        device_description,
        device_type,
        warranty,
        priority_level
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
      `,
      [
        workOrderValue.trim(),
        custName,
        jobDescription.trim(),
        deviceDescription ? deviceDescription.trim() : null,
        deviceType.trim(),
        warranty_to_set,
        priority_to_set
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
        t.sub_status,
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
        COALESCE(t.is_archived, FALSE) = FALSE
        AND (
         t.ticket_number ILIKE $1 OR
t.cust_name ILIKE $1 OR
t.issue_summary ILIKE $1 OR
t.device_type ILIKE $1 OR
TO_CHAR(t.created_at, 'YYYY') ILIKE $1 OR
TO_CHAR(t.created_at, 'MM/DD/YYYY') ILIKE $1 OR
TO_CHAR(t.created_at, 'YYYY-MM-DD') ILIKE $1 OR
TO_CHAR(t.created_at, 'Month DD, YYYY') ILIKE $1
        )
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
        t.sub_status,
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
        AND COALESCE(t.is_archived, FALSE) = FALSE
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
      WHERE is_active = TRUE
      ORDER BY technician_id ASC
    `);

    const ticketsResult = await pool.query(`
      SELECT
        t.ticket_id,
        t.ticket_number,
        t.cust_name,
        t.sub_status,
        t.issue_summary,
        t.device_description,
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
      WHERE COALESCE(t.is_archived, FALSE) = FALSE
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
  const { assignedTechnicianId, currentStatus, subStatus, sortOrder } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const existingResult = await client.query(
      `SELECT * FROM tickets WHERE ticket_id = $1 FOR UPDATE`,
      [ticketId]
    );

    if (existingResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Ticket not found' });
    }

    const oldTicket = existingResult.rows[0];

    const nextAssignedTechnicianId =
      assignedTechnicianId !== undefined
        ? assignedTechnicianId
        : oldTicket.assigned_technician_id;

    let nextStatus =
  currentStatus !== undefined
    ? currentStatus
    : oldTicket.current_status;

if (
  nextAssignedTechnicianId &&
  oldTicket.current_status === 'Waiting to Start' &&
  nextStatus === 'Waiting to Start'
) {
  nextStatus = 'In Progress';
}

    const nextSubStatus =
      subStatus !== undefined
        ? subStatus || null
        : oldTicket.sub_status;

    const nextSortOrder =
      sortOrder !== undefined
        ? sortOrder
        : oldTicket.sort_order;

    let nextStartedAt = oldTicket.started_at;
    let nextCompletedAt = oldTicket.completed_at;

    if (!nextStartedAt && nextAssignedTechnicianId) {
      nextStartedAt = new Date();
    }

    if (oldTicket.current_status !== nextStatus) {
      if (nextStatus === 'Done' && !nextCompletedAt) {
        nextCompletedAt = new Date();
      }
      if (oldTicket.current_status === 'Done' && nextStatus !== 'Done') {
        nextCompletedAt = null;
      }
    }

    const updateResult = await client.query(
      `
      UPDATE tickets
      SET
        assigned_technician_id = $1,
        current_status = $2,
        sub_status = $3,
        sort_order = $4,
        started_at = $5,
        completed_at = $6,
        updated_at = CURRENT_TIMESTAMP
      WHERE ticket_id = $7
      RETURNING *
      `,
      [
        nextAssignedTechnicianId,
        nextStatus,
        nextSubStatus,
        nextSortOrder,
        nextStartedAt,
        nextCompletedAt,
        ticketId
      ]
    );

    const updatedTicket = updateResult.rows[0];

    if (oldTicket.current_status !== nextStatus) {
      await client.query(
        `
        INSERT INTO ticket_events (
          ticket_id, event_type, old_status, new_status, technician_id
        )
        VALUES ($1, 'STATUS_CHANGE', $2, $3, $4)
        `,
        [ticketId, oldTicket.current_status, nextStatus, nextAssignedTechnicianId]
      );
    }

    if (oldTicket.sub_status !== nextSubStatus) {
      await client.query(
        `
        INSERT INTO ticket_events (
          ticket_id, event_type, old_status, new_status, technician_id
        )
        VALUES ($1, 'SUB_STATUS_CHANGE', $2, $3, $4)
        `,
        [ticketId, oldTicket.sub_status, nextSubStatus, nextAssignedTechnicianId]
      );
    }

    if (oldTicket.assigned_technician_id !== nextAssignedTechnicianId) {
      await client.query(
        `
        INSERT INTO ticket_events (
          ticket_id, event_type, technician_id
        )
        VALUES ($1, 'ASSIGNMENT_CHANGE', $2)
        `,
        [ticketId, nextAssignedTechnicianId]
      );
    }

    await client.query('COMMIT');

    res.json({
      message: 'Ticket updated successfully',
      ticket: updatedTicket
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Move ticket error:', err);
    res.status(500).json({ error: 'Failed to update ticket' });
  } finally {
    client.release();
  }
}

async function updateTicketDetails(req, res) {
  const { ticketNumber } = req.params;

  const {
    newTicketNumber,
    custName,
    issueSummary,
    deviceDescription,
    deviceType,
    priorityLevel
  } = req.body;

  if (!newTicketNumber || !custName || !issueSummary) {
    return res.status(400).json({ error: 'Ticket number, customer name, and issue are required.' });
  }

  try {
    const result = await pool.query(
      `
      UPDATE tickets
      SET
        ticket_number = $1,
        cust_name = $2,
        issue_summary = $3,
        device_description = $4,
        device_type = $5,
        priority_level = $6,
        updated_at = CURRENT_TIMESTAMP
      WHERE ticket_number = $7
        AND COALESCE(is_archived, FALSE) = FALSE
      RETURNING *
      `,
      [
        newTicketNumber.trim(),
        custName.trim(),
        issueSummary.trim(),
        deviceDescription ? deviceDescription.trim() : null,
        deviceType ? deviceType.trim() : null,
        priorityLevel || 'Normal',
        ticketNumber
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    res.json({
      message: 'Ticket details updated successfully',
      ticket: result.rows[0]
    });
  } catch (err) {
    console.error('Update ticket details error:', err);

    if (err.code === '23505') {
      return res.status(400).json({ error: 'That ticket number already exists.' });
    }

    res.status(500).json({ error: 'Failed to update ticket details' });
  }
}

async function deleteTicket(req, res) {
  const { ticketId } = req.params;

  try {
    const result = await pool.query(
      `
      UPDATE tickets
      SET
        cust_name = 'Archived Customer',
        issue_summary = '[Archived]',
        device_description = NULL,
        sub_status = NULL,
        is_archived = TRUE,
        picked_up_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
      WHERE ticket_id = $1
      RETURNING *
      `,
      [ticketId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    res.json({
      message: 'Ticket archived after pickup',
      ticket: result.rows[0]
    });
  } catch (err) {
    console.error('Archive ticket error:', err);
    res.status(500).json({ error: 'Failed to archive ticket' });
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
      JOIN tickets t ON t.ticket_id = e.ticket_id
      LEFT JOIN technicians tech ON e.technician_id = tech.technician_id
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
  getTicketHistory,
  updateTicketDetails,
  deleteTicket
};