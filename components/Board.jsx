import React, { useState } from "react";
import TicketCard from "./TicketCard";
import "./Board.css";


// Of this data from here 

const technicians = ["Ashton", "Billy", "Issac", "Worrer", "Noob", "Pringle", "SkullCrusher"];
const statuses = ["actively"];
const emptyTech = () => ({ actively: [] });

const initialTicketData = {};

const initialNewTickets = ["Walter White Mobo Failure", "John Doe Tune up", "Laptop Replacement", "Extra Laptop Setup"];


const Board = () => {
  const [ticketData, setTicketData] = useState(initialTicketData);
  const [newTickets, setNewTickets] = useState(initialNewTickets);
  const [resolvedTickets, setResolvedTickets] = useState([]);

  const techStartCol = 2;
  const resolvedCol = techStartCol + technicians.length;

  //to here needs to be replaced at some part with the actual backend connecition

  const removeTicketEverywhere = (ticket, data, newT, resolved) => {
    const next = structuredClone(data);
    for (const tech of Object.keys(next)) {
      for (const s of statuses) {
        next[tech][s] = next[tech][s].filter(t => t !== ticket);
      }
    }
    return {
      newData: next,
      newNew: newT.filter(t => t !== ticket),
      newResolved: resolved.filter(t => t !== ticket),
    };
  };
//
  //Handles the transfer of tickets from one section to another
  const handleDropOnTech = (e, tech) => {
    e.preventDefault();
    const ticket = e.dataTransfer.getData("ticket");
    const { newData, newNew, newResolved } = removeTicketEverywhere(ticket, ticketData, newTickets, resolvedTickets);

    if (!newData[tech]) newData[tech] = emptyTech();
    newData[tech].actively.push(ticket);

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets(newResolved);
  };

  const handleDropOnNew = (e) => {
    e.preventDefault();
    const ticket = e.dataTransfer.getData("ticket");
    const { newData, newNew, newResolved } = removeTicketEverywhere(ticket, ticketData, newTickets, resolvedTickets);

    setTicketData(newData);
    setNewTickets([...newNew, ticket]);
    setResolvedTickets(newResolved);
  };

  const handleDropOnResolved = (e) => {
    e.preventDefault();
    const ticket = e.dataTransfer.getData("ticket");
    const { newData, newNew, newResolved } = removeTicketEverywhere(ticket, ticketData, newTickets, resolvedTickets);

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets([...newResolved, ticket]);
  };

  return (
    <div className="board" style={{ "--techCount": technicians.length }}>
      <div className="header headerNew" style={{ gridColumn: 1 }}>New Tickets</div>
      {technicians.map((tech, i) => (
        <div className="header" key={tech} style={{ gridColumn: techStartCol + i }}>{tech}</div>
      ))}
      <div className="header headerResolved" style={{ gridColumn: resolvedCol }}>Resolved</div>

      <div
        className="cell cellNew"
        style={{ gridColumn: 1, gridRow: 2 }}
        onDragOver={(e) => e.preventDefault()}
        onDrop={handleDropOnNew}
      >
        {newTickets.map((ticket, i) => (
          <TicketCard key={i} ticket={ticket} type="new" />
        ))}
      </div>

      {technicians.map((tech, colIndex) => (
        <div
          className="cell"
          key={tech}
          style={{ gridColumn: techStartCol + colIndex, gridRow: 2 }}
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => handleDropOnTech(e, tech)}
        >
          {(ticketData[tech]?.actively || []).map((ticket, i) => (
            <TicketCard key={i} ticket={ticket} type="actively" />
          ))}
        </div>
      ))}

      <div
        className="cell cellResolved"
        style={{ gridColumn: resolvedCol, gridRow: 2 }}
        onDragOver={(e) => e.preventDefault()}
        onDrop={handleDropOnResolved}
      >
        {resolvedTickets.map((ticket, i) => (
          <TicketCard key={i} ticket={ticket} type="resolved" />
        ))}
      </div>
    </div>
  );
};

export default Board;