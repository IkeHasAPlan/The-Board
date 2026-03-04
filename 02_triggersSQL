--
-- The Board Triggers
-- 02_triggers.sql
--

-- Write status-change record to ticket_events
CREATE OR REPLACE FUNCTION log_ticket_status_change()
RETURNS TRIGGER AS $$
BEGIN
	-- Only log real status changes
	IF NEW.current_status IS DISTINCT FROM OLD.current_status THEN
		INSERT INTO ticket_events(
			ticket_id,
			event_type,
			old_status,
			new_status,
			technician_id
		)
		VALUES (
			NEW.ticket_id,
			'Status Change',
			OLD.current_status, 
			NEW.current_status,
			NEW.assigned_technician_id
		);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replaces trigger if it already exists
DROP TRIGGER IF EXISTS trigger_status_change ON tickets;
CREATE TRIGGER trigger_status_change 
AFTER UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_ticket_status_change();
