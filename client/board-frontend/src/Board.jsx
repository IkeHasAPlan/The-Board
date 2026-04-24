import React from "react";
import TicketCard from "./TicketCard";
import { useBoardState } from "./BoardController";
import "./Board.css";

function Board() {
  const {
    technicians,
    ticketData,
    newTickets,
    resolvedTickets,
    loading,
    error,
    handleDropOnTech,
    handleDropOnNew,
    handleDropOnResolved,
    handleStatusChange,
  } = useBoardState();

const handleDeleteTicket = async (ticket) => {
  const confirmed = window.confirm(
    `Remove ticket #${ticket.ticket_number} permanently?\n\nOnly do this after the customer has picked up their machine.`
  );

  if (!confirmed) return;

  try {
    const res = await fetch(`/tickets/${ticket.ticket_id}`, {
      method: "DELETE"
    });

    if (!res.ok) {
      throw new Error("Failed to delete ticket");
    }

    window.location.reload();
  } catch (err) {
    console.error(err);
    alert("Failed to remove ticket.");
  }
};

  const techStartCol = 2;
  const resolvedCol = techStartCol + technicians.length;

  if (loading) return <div>Loading board...</div>;
  if (error) return <div>{error}</div>;

  return (
    <div className="board" style={{ "--techCount": technicians.length }}>
      <div className="header headerNew" style={{ gridColumn: 1 }}>
        New Tickets
      </div>

      {technicians.map((tech, i) => (
        <div
          className="header"
          key={tech.technician_id}
          style={{ gridColumn: techStartCol + i }}
        >
          {tech.name}
        </div>
      ))}

      <div
        className="header headerResolved"
        style={{ gridColumn: resolvedCol }}
      >
        Resolved
      </div>

      <div
        className="cell cellNew"
        style={{ gridColumn: 1, gridRow: 2 }}
        onDragOver={(e) => e.preventDefault()}
        onDrop={handleDropOnNew}
      >
        {newTickets.map((ticket) => (
          <TicketCard
            key={ticket.ticket_id}
            ticket={ticket}
            type="new"
            onStatusChange={handleStatusChange}
          />
        ))}
      </div>

      {technicians.map((tech, colIndex) => (
        <div
          className="cell"
          key={tech.technician_id}
          style={{ gridColumn: techStartCol + colIndex, gridRow: 2 }}
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => handleDropOnTech(e, tech)}
        >
          {(ticketData[tech.name]?.actively || []).map((ticket) => (
            <TicketCard
              key={ticket.ticket_id}
              ticket={ticket}
              type="actively"
              onStatusChange={handleStatusChange}
            />
          ))}
        </div>
      ))}

      <div
        className="cell cellResolved"
        style={{ gridColumn: resolvedCol, gridRow: 2 }}
        onDragOver={(e) => e.preventDefault()}
        onDrop={handleDropOnResolved}
      >
        {resolvedTickets.map((ticket) => (
          <TicketCard
            key={ticket.ticket_id}
            ticket={ticket}
            type="resolved"
            onStatusChange={handleStatusChange}
            onDeleteTicket={handleDeleteTicket}
          />
        ))}
      </div>
    </div>
  );
}

export default Board;