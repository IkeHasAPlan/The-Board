--
-- The Board Triggers
-- triggers.sql
--

-- Automatically maintain tickets.updated_at
CREATE OR REPLACE FUNCTION set_ticket_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_ticket_updated_at ON tickets;
CREATE TRIGGER trigger_ticket_updated_at
BEFORE UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION set_ticket_updated_at();


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
      'STATUS_CHANGE',
      OLD.current_status,
      NEW.current_status,
      NEW.assigned_technician_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_status_change ON tickets;
CREATE TRIGGER trigger_status_change
AFTER UPDATE OF current_status ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_ticket_status_change();
