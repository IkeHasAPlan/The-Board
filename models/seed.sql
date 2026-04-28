--
-- The Board Seed Data
-- seed.sql
--

-- Technicians
INSERT INTO technicians (name, email)
VALUES
  ('Christian', 'christian@board.com'),
  ('Tai', 'tai@board.com'),
  ('Dakota', 'dakota@board.com'),
  ('Isaac', 'isaac@board.com'),
  ('Donovan', 'donovan@board.com'),
  ('Josh', 'josh@board.com'),
  ('David', 'david@board.com')
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name;

-- Tickets
-- NOTE: assigned_technician_id is looked up by email so IDs never matter.
INSERT INTO tickets (
  ticket_number,
  cust_name,
  issue_summary,
  device_type,
  warranty,
  priority_level,
  current_status,
  assigned_technician_id,
  sort_order
)
VALUES
  -- Unstarted column (unassigned)
  ('T2001', 'Taco Bell', 'Screen replacement', 'Laptop', TRUE, 'High', 'Waiting to Start', NULL, 1000),
  ('T2002', 'Professor X', 'Virus removal', 'Desktop', FALSE, 'Normal', 'Waiting to Start', NULL, 1000),

  ('T2003', 'Toronto Raptors', 'Battery not charging', 'Laptop', FALSE, 'Urgent', 'In Progress',
    (SELECT technician_id FROM technicians WHERE email='tai@board.com'), 0),
  ('T2004', 'Lu Lee', 'OS reinstall', 'Desktop', FALSE, 'Normal', 'Waiting for Customer Response',
    (SELECT technician_id FROM technicians WHERE email='tai@board.com'), 1000),
  ('T2005', 'Iron Man', 'Keyboard replacement (parts pending)', 'Laptop', TRUE, 'Normal', 'Waiting for Part',
    (SELECT technician_id FROM technicians WHERE email='tai@board.com'), 1000),

  ('T2006', 'Joohn Ceeena', 'Data transfer', 'Laptop', FALSE, 'Normal', 'In Progress',
    (SELECT technician_id FROM technicians WHERE email='isaac@board.com'), 0),
  ('T2007', 'Daft Punk', 'Device running slow', 'Desktop', FALSE, 'Low', 'Waiting to Start',
    (SELECT technician_id FROM technicians WHERE email='isaac@board.com'), 1000)

ON CONFLICT (ticket_number) DO UPDATE SET
  cust_name = EXCLUDED.cust_name,
  issue_summary = EXCLUDED.issue_summary,
  device_type = EXCLUDED.device_type,
  warranty = EXCLUDED.warranty,
  priority_level = EXCLUDED.priority_level,
  current_status = EXCLUDED.current_status,
  assigned_technician_id = EXCLUDED.assigned_technician_id,
  sort_order = EXCLUDED.sort_order;
