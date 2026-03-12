import "./TicketCard.css";

function TicketCard({ ticket, type }) {
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
      <div>{ticket.current_status}</div>
    </div>
  );
}

export default TicketCard;