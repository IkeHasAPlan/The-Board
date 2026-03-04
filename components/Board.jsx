import React from "react";
import TicketCard from "./TicketCard";
import "./Board.css";

// Technicians
const technicians = ["Ashton", "Billy", "Issac", "Worrer", "Noob", "Pringle", "SkullCrusher"];

// Status rows
const statusRows = [
  { key: "actively", label: "Working On" },
  { key: "waitingParts", label: "Waiting On Parts" },
  { key: "waitingCustomer", label: "Waiting for Customer Response" },
];

const newTickets = ["Walter White Mobo Failure"];

const ticketData = {
  "New Tickets": { actively: ["Walter White Mobo Failure"], waitingParts: [], waitingCustomer: [] },
  "Noob": { actively: ["John Doe Tune up"], waitingParts: ["Laptop Replacement"], waitingCustomer: ["Extra Laptop Setup"] },
};
// Resolved tickets
const resolvedTickets = [];

const Board = () => {
  const techStartCol = 2;
  const resolvedCol = techStartCol + technicians.length;
  return (
    <div className="board" style={{ "techCount": technicians.length }}>
      {/* Headers */}
      <div className="header headerNew" style={{ gridColumn: 1 }}>New Tickets</div>
      {technicians.map((tech, i) => (
        <div className="header" key={tech} style={{ gridColumn: techStartCol + i }}>
          {tech}
        </div>
      ))}
      <div className="header headerResolved" style={{ gridColumn: resolvedCol }}>
        Resolved
      </div>

  {/* New Tickets column */}
  <div
     className="cell cellNew"
     style={{gridColumn: 1, gridRow: "2 / span 3"}}
     >
      {newTickets.map((ticket, i) => (
        <TicketCard key={i} ticket={ticket} type="new" />
      ))}
  </div>


      {/* Technician cells */}
      {statusRows.map((row, rowIndex) =>
        technicians.map((tech, colIndex) => (
          <div
            className="cell"
            key={`${tech}-${row.key}`}
            style={{ gridColumn: techStartCol + colIndex, gridRow: rowIndex + 2 }}
          >
            <div className="rowLabel">{row.label}</div>
            {(ticketData[tech]?.[row.key] || []).map((ticket, i) => (
              <TicketCard key={i} ticket={ticket} type={row.key} />
            ))}
          </div>
        ))
      )}

      {/* Resolved column */}
      <div className="cell cellResolved">
        {resolvedTickets.map((ticket, i) => (
          <TicketCard key={i} ticket={ticket} type="resolved" />
        ))}
      </div>
    </div>
  );
};

export default Board;