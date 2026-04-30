--
-- The Board Seed Data
-- seed.sql
--

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
