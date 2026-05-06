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



-- Insert tickets (ALL waiting, no tech assigned yet)

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
