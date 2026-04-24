import { useEffect, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:3001";

const persistMove = async (ticketId, payload) => {
  const response = await fetch(`${API_BASE}/tickets/${ticketId}/move`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) throw new Error("Failed to persist ticket move");
  return response.json();
};

export function useBoardState() {
  const [technicians, setTechnicians] = useState([]);
  const [ticketData, setTicketData] = useState({});
  const [newTickets, setNewTickets] = useState([]);
  const [resolvedTickets, setResolvedTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadBoard() {
      try {
        setLoading(true);
        setError("");

        const response = await fetch(`${API_BASE}/tickets/board-data`);
        if (!response.ok) throw new Error("Failed to fetch board data");

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

  const handleDropOnTech = async (e, tech) => {
    e.preventDefault();
    const ticket = JSON.parse(e.dataTransfer.getData("ticket"));

const nextStatus = ticket.current_status === "Done"
  ? "Waiting to Start"
  : ticket.current_status;

    const movedTicket = {
      ...ticket,
      assigned_technician_id: tech.technician_id,
      technician_name: tech.name,
      current_status: nextStatus,
    };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket, ticketData, newTickets, resolvedTickets
    );

    if (!newData[tech.name]) newData[tech.name] = emptyTech();
    newData[tech.name].actively.push(movedTicket);

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets(newResolved);

    try {
      await persistMove(ticket.ticket_id, {
        assignedTechnicianId: tech.technician_id,
        currentStatus: nextStatus,
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
      ticket, ticketData, newTickets, resolvedTickets
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

    const movedTicket = { ...ticket, current_status: "Done" };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket, ticketData, newTickets, resolvedTickets
    );

    setTicketData(newData);
    setNewTickets(newNew);
    setResolvedTickets([...newResolved, movedTicket]);

    try {
      await persistMove(ticket.ticket_id, { currentStatus: "Done" });
    } catch (err) {
      console.error(err);
      alert("Could not save ticket move.");
      window.location.reload();
    }
  };

const handleStatusChange = async (ticket, newSubStatus) => {
  const updatedTicket = {
    ...ticket,
    sub_status: newSubStatus || null,
  };

  const { newData, newNew, newResolved } = removeTicketEverywhere(
    ticket, ticketData, newTickets, resolvedTickets
  );

  const next = structuredClone(newData);

  if (!updatedTicket.technician_name) {
    setNewTickets([...newNew, updatedTicket]);
  } else {
    next[updatedTicket.technician_name].actively.push(updatedTicket);
    setTicketData(next);
  }

  try {
    await persistMove(ticket.ticket_id, {
      subStatus: newSubStatus || null,
    });
  } catch (err) {
    console.error(err);
    alert("Failed to update sub-status");
    window.location.reload();
  }
};

  return {
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
  };
}

// --- Utils ---

export const emptyTech = () => ({ actively: [] });

export const removeTicketEverywhere = (ticket, data, newT, resolved) => {
  const next = structuredClone(data);

  for (const tech of Object.keys(next)) {
    next[tech].actively = next[tech].actively.filter(
      (t) => t.ticket_id !== ticket.ticket_id
    );
    next[tech].waiting = (next[tech].waiting || []).filter(
      (t) => t.ticket_id !== ticket.ticket_id
    );
  }

  return {
    newData: next,
    newNew: newT.filter((t) => t.ticket_id !== ticket.ticket_id),
    newResolved: resolved.filter((t) => t.ticket_id !== ticket.ticket_id),
  };
};