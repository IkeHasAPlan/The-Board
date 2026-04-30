import { useEffect, useRef, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE || "";

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

  const isSavingMoveRef = useRef(false);

  const loadBoard = async (showLoading = false) => {
    if (isSavingMoveRef.current) return;

    try {
      if (showLoading) setLoading(true);
      setError("");

      const response = await fetch(`${API_BASE}/tickets/board-data`);
      if (!response.ok) throw new Error("Failed to fetch board data");

      const data = await response.json();
      const fetchedTechnicians = data.technicians || [];
      const fetchedTickets = data.tickets || [];

      const techBuckets = {};
      fetchedTechnicians.forEach((tech) => {
        techBuckets[tech.name] = emptyTech();
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
  };

  useEffect(() => {
    loadBoard(true);

    const intervalId = setInterval(() => {
      loadBoard(false);
    }, 5000);

    return () => clearInterval(intervalId);
  }, []);

  const saveMove = async (ticketId, payload) => {
    isSavingMoveRef.current = true;

    try {
      await persistMove(ticketId, payload);
      await loadBoard(false);
    } catch (err) {
      console.error(err);
      alert("Could not save ticket move.");
      await loadBoard(false);
    } finally {
      isSavingMoveRef.current = false;
    }
  };

  const handleDropOnTech = async (e, tech) => {
    e.preventDefault();
    const ticket = JSON.parse(e.dataTransfer.getData("ticket"));

    const nextStatus =
  ticket.current_status === "Done" || ticket.current_status === "Waiting to Start"
    ? "In Progress"
    : ticket.current_status;
    const movedTicket = {
      ...ticket,
      assigned_technician_id: tech.technician_id,
      technician_name: tech.name,
      current_status: nextStatus,
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

    await saveMove(ticket.ticket_id, {
      assignedTechnicianId: tech.technician_id,
      currentStatus: nextStatus,
    });
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

    await saveMove(ticket.ticket_id, {
      assignedTechnicianId: null,
      currentStatus: "Waiting to Start",
    });
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

    await saveMove(ticket.ticket_id, {
      currentStatus: "Done",
    });
  };

  const handleStatusChange = async (ticket, newSubStatus) => {
    const updatedTicket = {
      ...ticket,
      sub_status: newSubStatus || null,
    };

    const { newData, newNew, newResolved } = removeTicketEverywhere(
      ticket,
      ticketData,
      newTickets,
      resolvedTickets
    );

    if (!updatedTicket.technician_name) {
      setNewTickets([...newNew, updatedTicket]);
      setTicketData(newData);
    } else {
      if (!newData[updatedTicket.technician_name]) {
        newData[updatedTicket.technician_name] = emptyTech();
      }
      newData[updatedTicket.technician_name].actively.push(updatedTicket);
      setTicketData(newData);
      setNewTickets(newNew);
    }

    setResolvedTickets(newResolved);

    await saveMove(ticket.ticket_id, {
      subStatus: newSubStatus || null,
    });
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

export const emptyTech = () => ({ actively: [] });

export const removeTicketEverywhere = (ticket, data, newT, resolved) => {
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