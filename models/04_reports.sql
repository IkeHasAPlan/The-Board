--
-- The Board Reports
-- 04_reports.sql
--

-- Backlog by status
SELECT
  current_status,
  COUNT(*) AS ticket_count
FROM tickets
GROUP BY current_status
ORDER BY ticket_count DESC, current_status;

-- Backlog by status and priority
SELECT
  current_status,
  priority_level,
  COUNT(*) AS ticket_count
FROM tickets
GROUP BY current_status, priority_level
ORDER BY current_status, ticket_count DESC, priority_level;

-- Active workload by technician
SELECT
  t.technician_id,
  t.name,
  COUNT(k.ticket_id) AS active_tickets
FROM technicians t
LEFT JOIN tickets k
  ON t.technician_id = k.assigned_technician_id
 AND k.current_status <> 'Done'
GROUP BY t.technician_id, t.name
ORDER BY active_tickets DESC, t.name;

-- Completed tickets by technician
SELECT
  t.technician_id,
  t.name,
  COUNT(k.ticket_id) AS completed_tickets
FROM technicians t
LEFT JOIN tickets k
  ON t.technician_id = k.assigned_technician_id
 AND k.current_status = 'Done'
GROUP BY t.technician_id, t.name
ORDER BY completed_tickets DESC, t.name;

-- Unassigned ticket counts
  current_status,
  COUNT(*) AS unassigned_tickets
FROM tickets
WHERE assigned_technician_id IS NULL
GROUP BY current_status
ORDER BY unassigned_tickets DESC, current_status;

-- Average completion time 
SELECT
  AVG(completed_at - started_at) AS avg_completion_time
FROM tickets
WHERE started_at IS NOT NULL
  AND completed_at IS NOT NULL;

-- Average completion time
SELECT
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) / 3600.0 AS avg_completion_hours
FROM tickets
WHERE started_at IS NOT NULL
  AND completed_at IS NOT NULL;

-- Average completion time by technician
SELECT
  COALESCE(t.name, 'Unassigned') AS technician_name,
  COUNT(*) AS completed_ticket_count,
  AVG(EXTRACT(EPOCH FROM (k.completed_at - k.started_at))) / 3600.0 AS avg_completion_hours
FROM tickets k
LEFT JOIN technicians t
  ON t.technician_id = k.assigned_technician_id
WHERE k.started_at IS NOT NULL
  AND k.completed_at IS NOT NULL
GROUP BY COALESCE(t.name, 'Unassigned')
ORDER BY avg_completion_hours DESC NULLS LAST, technician_name;

-- Active tickets 
SELECT
  ticket_id,
  ticket_number,
  cust_name,
  issue_summary,
  device_type,
  current_status,
  priority_level,
  assigned_technician_id,
  created_at,
  updated_at
FROM tickets
WHERE current_status <> 'Done'
ORDER BY
  -- priority ordering: Urgent first, then High, Normal, Low
  CASE priority_level
    WHEN 'Urgent' THEN 1
    WHEN 'High' THEN 2
    WHEN 'Normal' THEN 3
    WHEN 'Low' THEN 4
    ELSE 5
  END,
  created_at;

-- Tickets waiting for customer response
SELECT
  ticket_number,
  cust_name,
  issue_summary,
  assigned_technician_id,
  created_at,
  updated_at
FROM tickets
WHERE current_status = 'Waiting for Customer Response'
ORDER BY created_at;

-- Tickets waiting for part
SELECT
  ticket_number,
  cust_name,
  issue_summary,
  assigned_technician_id,
  created_at,
  updated_at
FROM tickets
WHERE current_status = 'Waiting for Part'
ORDER BY created_at;

-- Replace 'T1001' with whatever ticket number you want to look up
WITH ticket_base AS (
  SELECT
    k.*,
    t.name AS technician_name
  FROM tickets k
  LEFT JOIN technicians t
    ON t.technician_id = k.assigned_technician_id
  WHERE k.ticket_number = 'T1001'
),
event_rollup AS (
  SELECT
    e.ticket_id,
    MAX(e.event_timestamp) FILTER (WHERE e.event_type = 'STATUS_CHANGE') AS last_status_change_at,
    MAX(e.event_timestamp) FILTER (WHERE e.event_type = 'ASSIGNMENT_CHANGE') AS last_transfer_at
  FROM ticket_events e
  GROUP BY e.ticket_id
)
SELECT
  b.ticket_number,
  b.cust_name,
  b.issue_summary,
  b.device_type,
  b.priority_level,
  b.current_status,

  -- started/completed flags
  (b.started_at IS NOT NULL) AS has_started,
  (b.completed_at IS NOT NULL) AS has_completed,

  -- timestamps
  b.created_at,
  b.updated_at,
  b.started_at,
  b.completed_at,

  -- waiting state flags
  (b.current_status = 'Waiting for Customer Response') AS waiting_for_customer,
  (b.current_status = 'Waiting for Part') AS waiting_for_part,

  -- time worked
  CASE
    WHEN b.started_at IS NULL THEN NULL
    WHEN b.completed_at IS NULL THEN (CURRENT_TIMESTAMP - b.started_at)
    ELSE (b.completed_at - b.started_at)
  END AS time_worked,

  -- derived history timestamps from events
  r.last_status_change_at,
  r.last_transfer_at

FROM ticket_base b
LEFT JOIN event_rollup r
  ON r.ticket_id = b.ticket_id;

SELECT
  event_id,
  ticket_id,
  event_type,
  old_status,
  new_status,
  technician_id,
  event_timestamp
FROM ticket_events
ORDER BY event_timestamp DESC;
