const pool = require('../db');

async function getTechnicians(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        tech.technician_id,
        tech.name,
        tech.email,
        tech.is_active,
        COUNT(t.ticket_id) FILTER (WHERE t.current_status <> 'Done') AS assigned_tickets
      FROM technicians tech
      LEFT JOIN tickets t
        ON tech.technician_id = t.assigned_technician_id
      GROUP BY tech.technician_id, tech.name, tech.email, tech.is_active
      ORDER BY tech.is_active DESC, tech.name ASC
    `);

    res.json(result.rows);
  } catch (err) {
    console.error('Get technicians error:', err);
    res.status(500).json({ error: 'Failed to load technicians' });
  }
}

async function createTechnician(req, res) {
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required.' });
  }

  try {
    const result = await pool.query(
      `
      INSERT INTO technicians (name, email, is_active)
      VALUES ($1, $2, TRUE)
      RETURNING *
      `,
      [name.trim(), email.trim().toLowerCase()]
    );

    res.status(201).json({
      message: 'Technician created successfully.',
      technician: result.rows[0]
    });
  } catch (err) {
    console.error('Create technician error:', err);

    if (err.code === '23505') {
      return res.status(400).json({ error: 'That email already exists.' });
    }

    res.status(500).json({ error: 'Failed to create technician.' });
  }
}

async function updateTechnician(req, res) {
  const { id } = req.params;
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required.' });
  }

  try {
    const result = await pool.query(
      `
      UPDATE technicians
      SET name = $1,
          email = $2,
          updated_at = CURRENT_TIMESTAMP
      WHERE technician_id = $3
      RETURNING *
      `,
      [name.trim(), email.trim().toLowerCase(), id]
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

    if (err.code === '23505') {
      return res.status(400).json({ error: 'That email already exists.' });
    }

    res.status(500).json({ error: 'Failed to update technician.' });
  }
}

async function deactivateTechnician(req, res) {
  const { id } = req.params;

  try {
    await pool.query(
      `
      UPDATE tickets
      SET assigned_technician_id = NULL
      WHERE assigned_technician_id = $1
        AND current_status <> 'Done'
      `,
      [id]
    );

    const result = await pool.query(
      `
      UPDATE technicians
      SET is_active = FALSE,
          updated_at = CURRENT_TIMESTAMP
      WHERE technician_id = $1
      RETURNING *
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Technician not found.' });
    }

    res.json({
      message: 'Technician deactivated successfully.',
      technician: result.rows[0]
    });
  } catch (err) {
    console.error('Deactivate technician error:', err);
    res.status(500).json({ error: 'Failed to deactivate technician.' });
  }
}

module.exports = {
  getTechnicians,
  createTechnician,
  updateTechnician,
  deactivateTechnician
};
