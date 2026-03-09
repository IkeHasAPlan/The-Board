--
-- The Board Seed Data
-- seed.sql
--

-- Technicians
INSERT INTO technicians (name, email)
VALUES
  ('Isaac Rivera', 'isaac@board.com'),
  ('Gideon Masters', 'gideon@board.com'),
  ('Ashton Wooster', 'ashton@board.com'),
  ('Michael Forness', 'michael@board.com'),
  ('Bryson Allen', 'bryson@board.com')
ON CONFLICT (email) DO NOTHING;

-- Tickets 
INSERT INTO tickets (
  ticket_number,
  cust_name,
  issue_summary,
  device_type,
  priority_level,
  current_status,
  assigned_technician_id,
  started_at,
  completed_at
)
VALUES
  ('T1001', 'Godzilla', 'Screen replacement', 'Laptop', 'High', 'Waiting to Start',
    NULL, NULL, NULL),

  ('T1002', 'Pizza Hutt', 'Virus removal', 'Desktop', 'Normal', 'In Progress',
    (SELECT technician_id FROM technicians WHERE email='isaac@board.com'),
    CURRENT_TIMESTAMP, NULL),

  ('T1003', 'Larry Bird', 'Data transfer', 'Laptop', 'Urgent', 'Waiting for Part',
    (SELECT technician_id FROM technicians WHERE email='gideon@board.com'),
    CURRENT_TIMESTAMP, NULL),

  ('T1004', 'Professional Egyptian', 'Battery replacement', 'Laptop', 'Low', 'Done',
    (SELECT technician_id FROM technicians WHERE email='ashton@board.com'),
    CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),

  ('T1005', 'Saromon Ring', 'OS reinstall', 'Desktop', 'Normal', 'Waiting for Customer Response',
    (SELECT technician_id FROM technicians WHERE email='michael@board.com'),
    CURRENT_TIMESTAMP, NULL)
ON CONFLICT (ticket_number) DO NOTHING;

-- Event seeds
-- Insert a CREATED event for each seeded ticket 
INSERT INTO ticket_events (ticket_id, event_type, technician_id)
SELECT t.ticket_id, 'CREATED', t.assigned_technician_id
FROM tickets t
WHERE t.ticket_number IN ('T1001','T1002','T1003','T1004','T1005')
  AND NOT EXISTS (
    SELECT 1 FROM ticket_events e
    WHERE e.ticket_id = t.ticket_id
      AND e.event_type = 'CREATED'
  );
