-- 
-- The Board Schema
-- 01_schema.sql
--

-- Technicians 
CREATE TABLE IF NOT EXISTS technicians (
	technician_id SERIAL PRIMARY KEY, 
	name VARCHAR(100) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tickets - stored tickets to admin
CREATE TABLE IF NOT EXISTS tickets (
	ticket_id SERIAL PRIMARY KEY,
	ticket_number VARCHAR(50) NOT NULL UNIQUE,
	cust_name VARCHAR(100) NOT NULL,
	issue_summary TEXT NOT NULL,
	device_type VARCHAR(100),
	priority_level VARCHAR(20) NOT NULL DEFAULT 'Normal',
	current_status VARCHAR(50) NOT NULL DEFAULT 'Waiting to Start',
	assigned_technician_id INT,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	started_at TIMESTAMP,
	completed_at TIMESTAMP,

	CONSTRAINT fk_assigned_technician
		FOREIGN KEY (assigned_technician_id) 
		REFERENCES technicians(technician_id)
		ON DELETE SET NULL
);

-- Constraints - workflow and priority
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

-- Indexes - common board/admin queries
CREATE INDEX IF NOT EXISTS idx_ticket_status ON tickets(current_status); 
CREATE INDEX IF NOT EXISTS idx_ticket_technician ON tickets(assigned_technician_id); 
CREATE INDEX IF NOT EXISTS idx_ticket_created ON tickets(created_at); 
CREATE INDEX IF NOT EXISTS idx_ticket_completed_at ON tickets(completed_at);

CREATE INDEX IF NOT EXISTS idx_events_ticket ON ticket_events(ticket_id); 
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON ticket_events(event_timestamp);

