const pool = require('../db');

function formatNumber(value, fallback = 0) {
  if (value === null || value === undefined) return fallback;
  return Number(value);
}

async function getReportSummary(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*) FILTER (
          WHERE current_status = 'Done'
            AND completed_at >= date_trunc('week', CURRENT_DATE)
        ) AS jobs_completed_this_week,

        ROUND(
          AVG(
            CASE
              WHEN started_at IS NOT NULL AND completed_at IS NOT NULL
              THEN EXTRACT(EPOCH FROM (completed_at - started_at)) / 3600 / 8
              ELSE NULL
            END
          )::numeric,
          1
        ) AS avg_completion_days,

        COUNT(*) FILTER (
          WHERE current_status <> 'Done'
            AND COALESCE(is_archived, FALSE) = FALSE
        ) AS open_jobs
      FROM tickets;
    `);


    const row = result.rows[0];

    res.json({
      jobsCompletedThisWeek: formatNumber(row.jobs_completed_this_week),
      avgCompletionDays: row.avg_completion_days === null ? null : Number(row.avg_completion_days),
      openJobs: formatNumber(row.open_jobs),
    });
  } catch (err) {
    console.error('Get report summary error:', err);
    res.status(500).json({ error: 'Failed to load report summary.' });
  }
}

async function getTechnicianPerformance(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        tech.technician_id,
        tech.name AS technician,

        COUNT(t.ticket_id) FILTER (
          WHERE t.current_status = 'Done'
            AND t.completed_at >= date_trunc('week', CURRENT_DATE)
        ) AS jobs_completed,

        ROUND(
          AVG(
            CASE
              WHEN t.started_at IS NOT NULL AND t.completed_at IS NOT NULL
              THEN EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 3600 / 8
              ELSE NULL
            END
          )::numeric,
          1
        ) AS avg_time,

        COUNT(t.ticket_id) FILTER (
          WHERE t.current_status <> 'Done'
            AND COALESCE(t.is_archived, FALSE) = FALSE
        ) AS active_tickets


      FROM technicians tech
      LEFT JOIN tickets t
        ON tech.technician_id = t.assigned_technician_id
      WHERE tech.is_active = TRUE
      GROUP BY tech.technician_id, tech.name
      ORDER BY tech.technician_id ASC;
    `);

    res.json(result.rows);
  } catch (err) {
    console.error('Get technician performance error:', err);
    res.status(500).json({ error: 'Failed to load technician performance.' });
  }
}

module.exports = {
  getReportSummary,
  getTechnicianPerformance
};