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
-- NOTE: assigned_technician_id is looked up by email so IDs never matter.
INSERT INTO tickets (
  ticket_number,
  cust_name,
  issue_summary,
  device_type,
  priority_level,
  current_status,
  assigned_technician_id,
  sort_order
)
VALUES
  -- Unstarted column (unassigned)
  ('T2001', 'John Smith', 'Screen replacement', 'Laptop', 'High', 'Waiting to Start', NULL, 1000),
  ('T2002', 'Emily Clark', 'Virus removal', 'Desktop', 'Normal', 'Waiting to Start', NULL, 1000),

  -- Michael column (mix of statuses)
  ('T2003', 'Mia Johnson', 'Battery not charging', 'Laptop', 'Urgent', 'In Progress',
    (SELECT technician_id FROM technicians WHERE email='michael@board.com'), 0),
  ('T2004', 'Sarah Lee', 'OS reinstall', 'Desktop', 'Normal', 'Waiting for Customer Response',
    (SELECT technician_id FROM technicians WHERE email='michael@board.com'), 1000),
  ('T2005', 'Alex Carter', 'Keyboard replacement (parts pending)', 'Laptop', 'Normal', 'Waiting for Part',
    (SELECT technician_id FROM technicians WHERE email='michael@board.com'), 1000),

  -- Isaac column
  ('T2006', 'Noah Brown', 'Data transfer', 'Laptop', 'Normal', 'In Progress',
    (SELECT technician_id FROM technicians WHERE email='isaac@board.com'), 0),
  ('T2007', 'Olivia White', 'Device running slow', 'Desktop', 'Low', 'Waiting to Start',
    (SELECT technician_id FROM technicians WHERE email='isaac@board.com'), 1000)

ON CONFLICT (ticket_number) DO NOTHING;
