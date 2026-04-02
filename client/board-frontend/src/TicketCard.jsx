import "./TicketCard.css";

function TicketCard({ ticket, type, onStatusChange }) {
  const handleDragStart = (e) => {
    e.dataTransfer.setData("ticket", JSON.stringify(ticket));
    e.dataTransfer.setData("fromType", type);
  };

  return (
    <div
      className={`ticketCard ${type}`}
      draggable
      onDragStart={handleDragStart}
    >
      <div><strong>{ticket.ticket_number}</strong></div>
      <div>{ticket.cust_name}</div>
      <div>{ticket.issue_summary}</div>
      <select
        value={ticket.current_status || "Waiting to Start"}
        onChange={(e) => {
          e.stopPropagation();
          onStatusChange(ticket, e.target.value);
        }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <option value="Waiting to Start">Waiting to Start</option>
        <option value="In Progress">In Progress</option>
        <option value="Waiting for Customer Response">Waiting for Customer</option>
        <option value="Waiting for Part">Waiting for Part</option>
        <option value="Done">Done</option>
      </select>
    </div>
  );
}

export default TicketCard;