import "./TicketCard.css";

function TicketCard({ ticket, type }) {
  return (
    <div className="ticketCard" draggable>
      {ticket}
    </div>
  );
}

export default TicketCard;