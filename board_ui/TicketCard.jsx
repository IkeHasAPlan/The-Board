import "./TicketCard.css";

function TicketCard({ ticket, type }) {
  const handleDragStart = (e) => {
    e.dataTransfer.setData("ticket", ticket);
    e.dataTransfer.setData("fromType", type);
  };

  return (
    <div
      className={`ticketCard ${type}`}
      draggable
      onDragStart={handleDragStart}
    >
      {ticket}
    </div>
  );
}

export default TicketCard;