--
-- The Board Reports
-- reports.sql
--

-- Unassigned (left column) count
SELECT COUNT(*) AS unassigned_open_tickets
FROM tickets
WHERE assigned_technician_id IS NULL
  AND current_status <> 'Done';

-- Completed (right column) count
SELECT COUNT(*) AS completed_tickets
FROM tickets
WHERE current_status = 'Done';

-- Backlog by status (all tickets)
SELECT current_status, COUNT(*) AS ticket_count
FROM tickets
GROUP BY current_status
ORDER BY ticket_count DESC, current_status;

-- Active workload by technician (not Done)
SELECT t.name,
       COUNT(k.ticket_id) AS active_tickets
FROM technicians t
LEFT JOIN tickets k
  ON t.technician_id = k.assigned_technician_id
 AND k.current_status <> 'Done'
GROUP BY t.technician_id, t.name
ORDER BY active_tickets DESC, t.name;

-- Average completion time (hours)
SELECT AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) / 3600.0 AS avg_completion_hours
FROM tickets
WHERE started_at IS NOT NULL
  AND completed_at IS NOT NULL;

-- Board pull for one technician
-- Replace $1 with a technician_id in pgAdmin
SELECT ticket_id,
       ticket_number,
       cust_name,
       issue_summary,
       current_status,
       sort_order,
       created_at,
       updated_at
FROM tickets
WHERE assigned_technician_id = (SELECT technician_id FROM technicians WHERE email='michael@board.com')
  AND current_status <> 'Done'
ORDER BY
  CASE current_status
    WHEN 'In Progress' THEN 1
    WHEN 'Waiting to Start' THEN 2
    WHEN 'Waiting for Customer Response' THEN 3
    WHEN 'Waiting for Part' THEN 4
    ELSE 5
  END,
  sort_order,
  created_at;

-- Ticket event log (audit/history)
SELECT event_id,
       ticket_id,
       event_type,
       old_status,
       new_status,
       technician_id,
       event_timestamp
FROM ticket_events
ORDER BY event_timestamp DESC;
