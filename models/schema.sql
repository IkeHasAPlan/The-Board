-- 
-- The Board Schema
-- schema.sql
--

-- Technicians 
CREATE TABLE technicians (
  technician_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tickets - stored tickets to admin
CREATE TABLE IF NOT EXISTS tickets (
	ticket_id SERIAL PRIMARY KEY,
	ticket_number VARCHAR(50) NOT NULL UNIQUE,
	cust_name VARCHAR(100) NOT NULL,
	issue_summary TEXT NOT NULL,
	device_description TEXT,
	device_type VARCHAR(100),

	-- Priority is kept for reporting/labeling, not for board ordering
	priority_level VARCHAR(20) NOT NULL DEFAULT 'Normal',

	current_status VARCHAR(50) NOT NULL DEFAULT 'Waiting to Start',
	sub_status VARCHAR(100),
	assigned_technician_id INT,

	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	started_at TIMESTAMP,
	completed_at TIMESTAMP,
	is_archived BOOLEAN DEFAULT FALSE,
	picked_up_at TIMESTAMP,
	updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

	-- Board ordering inside each technician column/status bucket
	-- Lower numbers appear higher
	sort_order INT DEFAULT 1000,

	CONSTRAINT fk_assigned_technician
		FOREIGN KEY (assigned_technician_id) 
		REFERENCES technicians(technician_id)
		ON DELETE SET NULL
);

-- Constraints - workflow / priority
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS priority_check; 
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS status_check; 

ALTER TABLE tickets 
	ADD CONSTRAINT priority_check
	CHECK (priority_level IN ('Low', 'Normal', 'High', 'Urgent'));

ALTER TABLE tickets 
	ADD CONSTRAINT status_check
	CHECK ( 
		current_status IN (
			'Waiting to Start', 
			'In Progress',
			'Waiting for Customer Response',
			'Waiting for Part',
			'Done'
		)
	);

-- Ticket Events - history / audit log
CREATE TABLE IF NOT EXISTS ticket_events (
	event_id SERIAL PRIMARY KEY,
	ticket_id INT NOT NULL, 
	event_type VARCHAR(50) NOT NULL, 
	old_status VARCHAR(50), 
	new_status VARCHAR(50), 
	technician_id INT, 
	event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 

	CONSTRAINT fk_event_ticket 
		FOREIGN KEY (ticket_id) 
		REFERENCES tickets(ticket_id) 
		ON DELETE CASCADE, 

	CONSTRAINT fk_event_technician 
		FOREIGN KEY (technician_id)
		REFERENCES technicians(technician_id)
		ON DELETE SET NULL 
);

-- Enforce valid event types
ALTER TABLE ticket_events DROP CONSTRAINT IF EXISTS event_type_check;
ALTER TABLE ticket_events
	ADD CONSTRAINT event_type_check
	CHECK (event_type IN ('CREATED','STATUS_CHANGE','ASSIGNMENT_CHANGE','PRIORITY_CHANGE','SUB_STATUS_CHANGE'));

-- Indexes - common board / admin queries
CREATE INDEX IF NOT EXISTS idx_ticket_status ON tickets(current_status); 
CREATE INDEX IF NOT EXISTS idx_ticket_technician ON tickets(assigned_technician_id); 
CREATE INDEX IF NOT EXISTS idx_ticket_created ON tickets(created_at); 
CREATE INDEX IF NOT EXISTS idx_ticket_completed_at ON tickets(completed_at);

CREATE INDEX IF NOT EXISTS idx_events_ticket ON ticket_events(ticket_id); 
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON ticket_events(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_events_ticket_time_desc
ON ticket_events(ticket_id, event_timestamp DESC);

-- Board retrieval index
CREATE INDEX IF NOT EXISTS idx_ticket_board
ON tickets(assigned_technician_id, current_status, sort_order, created_at);



