const pool = require('../db');

async function getReportSummary(req, res) {
  try {
    const jobsCompletedQuery = `
      SELECT COUNT(*) AS jobs_completed_this_week
      FROM tickets
      WHERE current_status = 'Done'
        AND completed_at >= date_trunc('week', CURRENT_DATE)
    `;

    const avgCompletionQuery = `
      SELECT ROUND(
        AVG(EXTRACT(EPOCH FROM (completed_at - created_at)) / 86400)::numeric,
        1
      ) AS avg_completion_days
      FROM tickets
      WHERE completed_at IS NOT NULL
    `;

    const openJobsQuery = `
      SELECT COUNT(*) AS open_jobs
      FROM tickets
      WHERE current_status <> 'Done'
    `;

    const mostCommonJobQuery = `
      SELECT device_type, COUNT(*) AS total
      FROM tickets
      WHERE device_type IS NOT NULL
      GROUP BY device_type
      ORDER BY total DESC, device_type ASC
      LIMIT 1
    `;

    const [jobsCompletedResult, avgCompletionResult, openJobsResult, mostCommonJobResult] =
      await Promise.all([
        pool.query(jobsCompletedQuery),
        pool.query(avgCompletionQuery),
        pool.query(openJobsQuery),
        pool.query(mostCommonJobQuery)
      ]);

    res.json({
      jobsCompletedThisWeek: Number(jobsCompletedResult.rows[0]?.jobs_completed_this_week || 0),
      avgCompletionDays: avgCompletionResult.rows[0]?.avg_completion_days || null,
      openJobs: Number(openJobsResult.rows[0]?.open_jobs || 0),
      mostCommonJobType: mostCommonJobResult.rows[0]?.device_type || 'N/A'
    });
  } catch (err) {
    console.error('Get report summary error:', err);
    res.status(500).json({ error: 'Failed to load report summary.' });
  }
}

async function getTechnicianPerformance(req, res) {
  try {
    const query = `
      SELECT
        tech.technician_id,
        tech.name AS technician,
        COUNT(t.ticket_id) FILTER (WHERE t.current_status = 'Done') AS jobs_completed,
        ROUND(
          AVG(
            EXTRACT(EPOCH FROM (t.completed_at - t.created_at)) / 86400
          ) FILTER (WHERE t.completed_at IS NOT NULL)::numeric,
          1
        ) AS avg_time,
        COUNT(t.ticket_id) FILTER (WHERE t.current_status <> 'Done') AS active_tickets,
        (
          SELECT t2.device_type
          FROM tickets t2
          WHERE t2.assigned_technician_id = tech.technician_id
            AND t2.device_type IS NOT NULL
          GROUP BY t2.device_type
          ORDER BY COUNT(*) DESC, t2.device_type ASC
          LIMIT 1
        ) AS common_job
      FROM technicians tech
      LEFT JOIN tickets t
        ON tech.technician_id = t.assigned_technician_id
      GROUP BY tech.technician_id, tech.name
      ORDER BY jobs_completed DESC, tech.name ASC
    `;

    const result = await pool.query(query);
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
