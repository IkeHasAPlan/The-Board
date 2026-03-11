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


-- Automatically set started_at / completed_at based on status transitions
CREATE OR REPLACE FUNCTION set_ticket_lifecycle_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_status IS DISTINCT FROM OLD.current_status THEN

    IF NEW.current_status = 'In Progress' AND OLD.started_at IS NULL THEN
      NEW.started_at = COALESCE(NEW.started_at, CURRENT_TIMESTAMP);
    END IF;

    IF NEW.current_status = 'Done' THEN
      NEW.completed_at = COALESCE(NEW.completed_at, CURRENT_TIMESTAMP);
    END IF;

    IF OLD.current_status = 'Done' AND NEW.current_status <> 'Done' THEN
      NEW.completed_at = NULL;
    END IF;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_lifecycle_timestamps ON tickets;
CREATE TRIGGER trigger_set_lifecycle_timestamps
BEFORE UPDATE OF current_status ON tickets
FOR EACH ROW
EXECUTE FUNCTION set_ticket_lifecycle_timestamps();


-- Write status-change record to ticket_events
CREATE OR REPLACE FUNCTION log_ticket_status_change()
RETURNS TRIGGER AS $$
BEGIN
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


-- Write assignment-change record to ticket_events
CREATE OR REPLACE FUNCTION log_ticket_assignment_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.assigned_technician_id IS DISTINCT FROM OLD.assigned_technician_id THEN
    INSERT INTO ticket_events(
      ticket_id,
      event_type,
      technician_id
    )
    VALUES (
      NEW.ticket_id,
      'ASSIGNMENT_CHANGE',
      NEW.assigned_technician_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_assignment_change ON tickets;
CREATE TRIGGER trigger_assignment_change
AFTER UPDATE OF assigned_technician_id ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_ticket_assignment_change();

