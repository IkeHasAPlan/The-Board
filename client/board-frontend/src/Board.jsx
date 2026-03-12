import React, { useEffect, useState } from "react";
import TicketCard from "./TicketCard";
import "./Board.css";

const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:3001";

const emptyTech = () => ({ actively: [] });

function Board() {
  const [technicians, setTechnicians] = useState([]);
  const [ticketData, setTicketData] = useState({});
  const [newTickets, setNewTickets] = useState([]);
  const [resolvedTickets, setResolvedTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const techStartCol = 2;
  const resolvedCol = techStartCol + technicians.length;

  useEffect(() => {
    async function loadBoard() {
      try {
        setLoading(true);
        setError("");

        const response = await fetch(`${API_BASE}/tickets/board-data`);
        if (!response.ok) {
          throw new Error("Failed to fetch board data");
        }

        const data = await response.json();
        const fetchedTechnicians = data.technicians || [];
        const fetchedTickets = data.tickets || [];

        const techNames = fetchedTechnicians.map((tech) => tech.name);
        const techBuckets = {};

        techNames.forEach((name) => {
          techBuckets[name] = emptyTech();
        });

        const newBucket = [];
        const resolvedBucket = [];

        fetchedTickets.forEach((ticket) => {
          if (ticket.current_status === "Done") {
            resolvedBucket.push(ticket);
          } else if (ticket.technician_name && techBuckets[ticket.technician_name]) {
            techBuckets[ticket.technician_name].actively.push(ticket);
          } else {
            newBucket.push(ticket);
          }
        });

        setTechnicians(fetchedTechnicians);
        setTicketData(techBuckets);
        setNewTickets(newBucket);
        setResolvedTickets(resolvedBucket);
      } catch (err) {
        console.error(err);
        setError("Could not load board data.");
      } finally {
        setLoading(false);
      }
    }

    loadBoard();
  }, []);

  const persistMove = async (ticketId, payload) => {
    const response = await fetch(`${API_BASE}/tickets/${ticketId}/move`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error("Failed to persist ticket move");
    }

    return response.json();
  };

  const removeTicketEverywhere = (ticket, data, newT, resolved) => {
    const next = structuredClone(data);

    for (const tech of Object.keys(next)) {
      next[tech].actively = next[tech].actively.filter(
        (t) => t.ticket_id !== ticket.ticket_id
      );
    }

    return {
      newData: next,
      newNew: newT.filter((t) => t.ticket_id !== ticket.ticket_id),
      newResolved: resolved.filter((t) => t.ticket_id !== ticket.ticket_id),
    };
  };

  const handleDropOnTech = async (e, tech) => {
    e.preventDefault();
    const ticket = JSON.parse(e.dataTransfer.getData("ticket"));

    const movedTicket = {
      ...ticket,
      assigned_technician_id: tech.technician_id,
      technician_name: tech.name,
      current_status:
        ticket.current_status === "Waiting to Start"
          ? "In Progress"
          : ticket.current_status,
    };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket,
      ticketData,
      newTickets,
      resolvedTickets
    );

    if (!newData[tech.name]) newData[tech.name] = emptyTech();
    newData[tech.name].actively.push(movedTicket);

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets(newResolved);

    try {
      await persistMove(ticket.ticket_id, {
        assignedTechnicianId: tech.technician_id,
        currentStatus:
          ticket.current_status === "Waiting to Start"
            ? "In Progress"
            : ticket.current_status,
      });
    } catch (err) {
      console.error(err);
      alert("Could not save ticket move.");
      window.location.reload();
    }
  };

  const handleDropOnNew = async (e) => {
    e.preventDefault();
    const ticket = JSON.parse(e.dataTransfer.getData("ticket"));

    const movedTicket = {
      ...ticket,
      assigned_technician_id: null,
      technician_name: null,
      current_status: "Waiting to Start",
    };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket,
      ticketData,
      newTickets,
      resolvedTickets
    );

    setTicketData(newData);
    setNewTickets([...newNew, movedTicket]);
    setResolvedTickets(newResolved);

    try {
      await persistMove(ticket.ticket_id, {
        assignedTechnicianId: null,
        currentStatus: "Waiting to Start",
      });
    } catch (err) {
      console.error(err);
      alert("Could not save ticket move.");
      window.location.reload();
    }
  };

  const handleDropOnResolved = async (e) => {
    e.preventDefault();
    const ticket = JSON.parse(e.dataTransfer.getData("ticket"));

    const movedTicket = {
      ...ticket,
      current_status: "Done",
    };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket,
      ticketData,
      newTickets,
      resolvedTickets
    );

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets([...newResolved, movedTicket]);

    try {
      await persistMove(ticket.ticket_id, {
        currentStatus: "Done",
      });
    } catch (err) {
      console.error(err);
      alert("Could not save ticket move.");
      window.location.reload();
    }
  };

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
          <TicketCard key={ticket.ticket_id} ticket={ticket} type="new" />
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
          <TicketCard key={ticket.ticket_id} ticket={ticket} type="resolved" />
        ))}
      </div>
    </div>
  );
}

export default Board;