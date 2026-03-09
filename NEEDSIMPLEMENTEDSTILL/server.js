const express = require('express')
const cors = require('cors')
const pool = require('./db')

const app = express()
const PORT = 3001

app.use(cors())
app.use(express.json())

app.get('/', (req, res) => {
  res.send('Backend is running')
})

app.get('/tickets/search', async (req, res) => {
  const name = req.query.name || ''

  try {
    const result = await pool.query(
      `
      SELECT
        ticket_id,
        ticket_number,
        cust_name,
        issue_summary,
        device_type,
        priority_level,
        current_status,
        assigned_technician_id,
        created_at,
        updated_at
      FROM tickets
      WHERE cust_name ILIKE $1
      ORDER BY created_at DESC
      `,
      [`%${name}%`]
    )

    res.json(result.rows)
  } catch (error) {
    console.error('Search error:', error)
    res.status(500).json({ error: 'Server error' })
  }
})

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})