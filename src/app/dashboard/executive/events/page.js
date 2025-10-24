'use client';

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function ManageEvents() {
  const router = useRouter();
  const [events, setEvents] = useState([]);
  const [form, setForm] = useState({ title: "", description: "", date: "", club_id: "" });
  const [clubs, setClubs] = useState([]);

  useEffect(() => {
    const verify = async () => {
      const res = await fetch("/api/user");
      if (res.ok) {
        const data = await res.json();
        if (data.role !== "executive") {
          alert("Access Denied: Executives Only");
          router.push(`/dashboard/${data.role}`);
        } else {
          loadEvents();
          loadClubs();
        }
      } else router.push("/");
    };
    verify();
  }, [router]);

  const loadEvents = async () => {
    const res = await fetch("/api/events");
    if (res.ok) setEvents(await res.json());
  };

  const loadClubs = async () => {
    const res = await fetch("/api/clubs");
    if (res.ok) setClubs(await res.json());
  };

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    const res = await fetch("/api/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    if (res.ok) {
      alert("Event created!");
      setForm({ title: "", description: "", date: "", club_id: "" });
      loadEvents();
    }
  };

  const handleDelete = async (id) => {
    if (!confirm("Delete this event?")) return;
    await fetch(`/api/events?id=${id}`, { method: "DELETE" });
    loadEvents();
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-indigo-600 mb-6">🎉 Manage Events</h1>

      <form onSubmit={handleSubmit} className="flex flex-wrap gap-3 mb-8">
        <input
          name="title"
          placeholder="Event Title"
          value={form.title}
          onChange={handleChange}
          required
          className="p-2 border rounded-lg w-1/4"
        />
        <input
          name="description"
          placeholder="Description"
          value={form.description}
          onChange={handleChange}
          required
          className="p-2 border rounded-lg w-1/3"
        />
        <input
          type="date"
          name="date"
          value={form.date}
          onChange={handleChange}
          required
          className="p-2 border rounded-lg"
        />
        <select
          name="club_id"
          value={form.club_id}
          onChange={handleChange}
          required
          className="p-2 border rounded-lg"
        >
          <option value="">Select Club</option>
          {clubs.map((club) => (
            <option key={club.id} value={club.id}>
              {club.name}
            </option>
          ))}
        </select>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg">
          Add Event
        </button>
      </form>

      <ul className="space-y-3">
        {events.map((ev) => (
          <li
            key={ev.id}
            className="p-4 bg-white rounded-lg shadow flex justify-between"
          >
            <div>
              <h3 className="font-semibold text-gray-800">{ev.title}</h3>
              <p className="text-sm text-gray-600">{ev.description}</p>
              <p className="text-xs text-gray-500">📅 {ev.date}</p>
            </div>
            <button
              onClick={() => handleDelete(ev.id)}
              className="bg-red-500 text-white px-3 py-1 rounded-lg"
            >
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
