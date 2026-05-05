--
-- The Board Seed Data
-- seed.sql
--
--
-- The Board Seed Data (All Tickets Start in Waiting)
--

-- Technicians
INSERT INTO technicians (name, email, is_active)
VALUES
  ('Tai', 'tai@board.com', TRUE),
  ('Dakota', 'dakota@board.com', TRUE),
  ('Isaac', 'isaac@board.com', TRUE),
  ('Donovan', 'donovan@board.com', TRUE),
  ('Josh', 'josh@board.com', TRUE),
  ('David', 'david@board.com', TRUE)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  is_active = TRUE;

-- Remove existing seed tickets
DELETE FROM tickets
WHERE ticket_number IN (
  '48213', '59382', '77429', '66104',
  '90517', '33862', '44091', '72844'
);

-- Insert tickets (ALL waiting, no tech assigned yet)
INSERT INTO tickets (
  ticket_number,
  cust_name,
  issue_summary,
  device_description,
  device_type,
  warranty,
  priority_level,
  current_status,
  sub_status,
  assigned_technician_id,
  created_at,
  started_at,
  completed_at,
  is_archived,
  picked_up_at,
  sort_order
)
VALUES
('48213', 'Fang Wang', 'Unity won''t run', 'Dell Inspiron', 'Laptop', FALSE, 'Normal', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '5 days', NULL, NULL, FALSE, NULL, 100),

('59382', 'Michael Tompkins', 'Blender crashes laptop', 'HP Envy', 'Laptop', TRUE, 'Urgent', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '6 days', NULL, NULL, FALSE, NULL, 110),

('77429', 'Kristofferson Culmer', 'Motherboard replacement', 'MacBook', 'Laptop', TRUE, 'Urgent', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '7 days', NULL, NULL, FALSE, NULL, 120),

('66104', 'Chip Gubera', 'Screen replacement', 'HP Notebook', 'Laptop', FALSE, 'Normal', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '4 days', NULL, NULL, FALSE, NULL, 130),

('90517', 'Jiaming Jiang', 'Corrupted OS', 'Dell XPS', 'Laptop', TRUE, 'Urgent', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '2 days', NULL, NULL, FALSE, NULL, 140),

('33862', 'Scottie Murrell', 'WiFi won''t work', 'ASUS Zenbook', 'Laptop', FALSE, 'Normal', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '3 days', NULL, NULL, FALSE, NULL, 150),

('44091', 'Noor Al-Shakarji', 'Virus removal', 'Lenovo Ideapad', 'Laptop', FALSE, 'Normal', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '4 days', NULL, NULL, FALSE, NULL, 160),

('72844', 'Michael Tompkins', 'Full diagnostic', 'HP Pavilion', 'Laptop', FALSE, 'Normal', 'Waiting to Start', 'New intake', NULL, NOW() - INTERVAL '3 days', NULL, NULL, FALSE, NULL, 170);

-- Remove any existing events for these tickets
DELETE FROM ticket_events
WHERE ticket_id IN (
  SELECT ticket_id FROM tickets
  WHERE ticket_number IN (
    '48213', '59382', '77429', '66104',
    '90517', '33862', '44091', '72844'
  )
);

-- Only CREATED events (no technician yet)
INSERT INTO ticket_events (
  ticket_id,
  event_type,
  old_status,
  new_status,
  technician_id,
  event_timestamp
)
SELECT
  ticket_id,
  'CREATED',
  NULL,
  'Waiting to Start',
  NULL,
  created_at
FROM tickets
WHERE ticket_number IN (
  '48213', '59382', '77429', '66104',
  '90517', '33862', '44091', '72844'
);
-- Technicians
INSERT INTO technicians (name, email)
VALUES
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
