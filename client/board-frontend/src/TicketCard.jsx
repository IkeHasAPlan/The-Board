import "./TicketCard.css";

function TicketCard({ ticket, type, onStatusChange, onDeleteTicket }) {
  const handleDragStart = (e) => {
    e.dataTransfer.setData("ticket", JSON.stringify(ticket));
    e.dataTransfer.setData("fromType", type);
  };

  const showPickedUpButton =
    type === "resolved" || ticket.current_status === "Done";

  const statusClass = {
  "Waiting for Customer Response": "status-waiting-customer",
  "Waiting for Part": "status-waiting-part",
    }[ticket.sub_status] || "";
  return (
    <div
      className={`ticketCard ${type} ${statusClass}`}
      draggable
      onDragStart={handleDragStart}
    >
      <div className="ticketTopRow">
        <div className="ticketNumber">{ticket.ticket_number}</div>

        <div
          className={`priorityBadge priority-${(ticket.priority_level || "Normal")
            .toLowerCase()
            .replace(/\s+/g, "-")}`}
        >
          {ticket.priority_level || "Normal"}
        </div>
      </div>

      <div className="ticketName">{ticket.cust_name}</div>

      <div className="ticketMeta">
        <span className="ticketDevice">
          {ticket.device_description || ticket.device_type || "Unknown Device"}        </span>
      </div>

      <div className="ticketIssue">{ticket.issue_summary}</div>

      <select
        className="statusSelect"
        value={ticket.sub_status || ""}
        onChange={(e) => {
          e.stopPropagation();
          onStatusChange(ticket, e.target.value);
        }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <option value="">No special status</option>
        <option value="Waiting for Customer Response">
          Waiting for Customer
        </option>
        <option value="Waiting for Part">Waiting for Part</option>
      </select>

      {showPickedUpButton && (
        <button
          className="pickedUpButton"
          onClick={(e) => {
            e.stopPropagation();
            onDeleteTicket(ticket);
          }}
        >
          Picked Up
        </button>
      )}
    </div>
  );
}

export default TicketCard;