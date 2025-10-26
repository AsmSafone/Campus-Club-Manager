'use client';

import { useEffect, useState } from "react";

export default function PublicEvents() {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    fetch("/api/events")
      .then((res) => res.json())
      .then(setEvents);
  }, []);

  const handleEventRegister = async (eventId) => {
    const res = await fetch("/api/events/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ eventId }),
    });
    if (res.ok) {
      alert("Successfully registered for the event!");
    } else {
      alert("Failed to register for the event.");
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-indigo-600 mb-6">🌍 Public Events</h1>
      <ul className="space-y-3">
        {events.map((ev) => (
          <li
            key={ev.event_id}
            className="p-4 bg-white rounded-lg shadow flex justify-between"
          >
            <div className="flex flex-col gap-2">
              <h3 className="font-semibold">{ev.title}</h3>
              <p className="text-gray-700">{ev.description}</p>
              <p className="text-sm text-gray-500">📅 {ev.date}</p>
              <p className="text-sm text-gray-500">📌 {ev.venue}</p>
            </div>
            <div className="">
              <button
                onClick={() => handleEventRegister(ev.event_id)}
                className="bg-blue-500 text-white px-3 py-1 rounded-lg"
              >
                Register
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
