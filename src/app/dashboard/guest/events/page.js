'use client';

import { useEffect, useState } from "react";

export default function PublicEvents() {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    fetch("/api/events")
      .then((res) => res.json())
      .then(setEvents);
  }, []);

  return (
    <div>
      <h1 className="text-3xl font-bold text-indigo-600 mb-6">🌍 Public Events</h1>
      <ul className="space-y-3">
        {events.map((ev) => (
          <li
            key={ev.id}
            className="p-4 bg-white rounded-lg shadow"
          >
            <h3 className="font-semibold">{ev.title}</h3>
            <p className="text-gray-700">{ev.description}</p>
            <p className="text-sm text-gray-500">📅 {ev.date}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
