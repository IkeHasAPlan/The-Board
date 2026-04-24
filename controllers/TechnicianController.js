const pool = require('../db');

async function getTechnicians(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        tech.technician_id,
        tech.name,
        tech.email,
        tech.is_active,
        COUNT(t.ticket_id) FILTER (
          WHERE COALESCE(t.is_archived, FALSE) = FALSE
            AND t.current_status <> 'Done'
        ) AS assigned_tickets
      FROM technicians tech
      LEFT JOIN tickets t
        ON tech.technician_id = t.assigned_technician_id
      GROUP BY tech.technician_id, tech.name, tech.email, tech.is_active
      ORDER BY tech.is_active DESC, tech.technician_id ASC
    `);

    res.json(result.rows);
  } catch (err) {
    console.error('Get technicians error:', err);
    res.status(500).json({ error: 'Failed to load technicians' });
  }
}

async function createTechnician(req, res) {
  const { name } = req.body;

  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Name is required.' });
  }

  const cleanName = name.trim();

  try {
    const result = await pool.query(
      `
      INSERT INTO technicians (name, email, is_active)
      VALUES ($1, $2, TRUE)
      RETURNING *
      `,
      [cleanName, `${cleanName.toLowerCase().replace(/\s+/g, '')}@placeholder.local`]
    );

    res.status(201).json({
      message: 'Technician created successfully.',
      technician: result.rows[0]
    });
  } catch (err) {
    console.error('Create technician error:', err);
    res.status(500).json({ error: 'Failed to create technician.' });
  }
}

async function updateTechnician(req, res) {
  const { id } = req.params;
  const { name, isActive } = req.body;

  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Name is required.' });
  }

  try {
    const result = await pool.query(
      `
      UPDATE technicians
      SET
        name = $1,
        is_active = COALESCE($2, is_active),
        updated_at = CURRENT_TIMESTAMP
      WHERE technician_id = $3
      RETURNING *
      `,
      [
        name.trim(),
        typeof isActive === 'boolean' ? isActive : null,
        id
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Technician not found.' });
    }

    res.json({
      message: 'Technician updated successfully.',
      technician: result.rows[0]
    });
  } catch (err) {
    console.error('Update technician error:', err);
    res.status(500).json({ error: 'Failed to update technician.' });
  }
}

async function deactivateTechnician(req, res) {
  const { id } = req.params;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const techResult = await client.query(
      `
      SELECT technician_id, name, is_active
      FROM technicians
      WHERE technician_id = $1
      FOR UPDATE
      `,
      [id]
    );

    if (techResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Technician not found.' });
    }

    const tech = techResult.rows[0];

    const ticketsResult = await client.query(
      `
      SELECT ticket_id, current_status
      FROM tickets
      WHERE assigned_technician_id = $1
        AND current_status <> 'Done'
        AND COALESCE(is_archived, FALSE) = FALSE
      FOR UPDATE
      `,
      [id]
    );

    for (const ticket of ticketsResult.rows) {
      await client.query(
        `
        UPDATE tickets
        SET
          assigned_technician_id = NULL,
          current_status = 'Waiting to Start',
          sub_status = NULL,
          updated_at = CURRENT_TIMESTAMP
        WHERE ticket_id = $1
        `,
        [ticket.ticket_id]
      );

      if (ticket.current_status !== 'Waiting to Start') {
        await client.query(
          `
          INSERT INTO ticket_events (
            ticket_id,
            event_type,
            old_status,
            new_status,
            technician_id
          )
          VALUES ($1, 'STATUS_CHANGE', $2, 'Waiting to Start', $3)
          `,
          [ticket.ticket_id, ticket.current_status, id]
        );
      }

      await client.query(
        `
        INSERT INTO ticket_events (
          ticket_id,
          event_type,
          technician_id
        )
        VALUES ($1, 'ASSIGNMENT_CHANGE', $2)
        `,
        [ticket.ticket_id, id]
      );
    }

    const result = await client.query(
      `
      UPDATE technicians
      SET is_active = FALSE,
          updated_at = CURRENT_TIMESTAMP
      WHERE technician_id = $1
      RETURNING *
      `,
      [id]
    );

    await client.query('COMMIT');

    res.json({
      message: `${tech.name} deactivated. ${ticketsResult.rows.length} active ticket(s) moved to Waiting to Start.`,
      technician: result.rows[0],
      movedTickets: ticketsResult.rows.length
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Deactivate technician error:', err);
    res.status(500).json({ error: 'Failed to deactivate technician.' });
  } finally {
    client.release();
  }
}

module.exports = {
  getTechnicians,
  createTechnician,
  updateTechnician,
  deactivateTechnician
};