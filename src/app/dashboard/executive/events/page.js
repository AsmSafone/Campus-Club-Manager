'use client';

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function ManageEvents() {
  const router = useRouter();
  const [events, setEvents] = useState([]);
  const [form, setForm] = useState({ title: "", description: "", date: "", club_id: "", venue: "" });
  const [myClub, setMyClub] = useState({})

  const loadMyClub = async () => {
    const res = await fetch("/api/executive/club");
    if (res.ok) {
      res.json().then(data => setMyClub(data) & setForm({ ...form, club_id: data.club_id }) & loadEvents(data.club_id));
    } else {
      alert("Failed to load your club data.");
    }
  }

  useEffect(() => {
    const verify = async () => {
      const res = await fetch("/api/user");
      if (res.ok) {
        const data = await res.json();
        if (data.role !== "executive") {
          alert("Access Denied: Executives Only");
          router.push(`/dashboard/${data.role}`);
        } else {
          loadMyClub();
        }
      } else router.push("/");
    };
    verify();
  }, [router]);

  const loadEvents = async (clubId) => {
    const res = await fetch("/api/executive/club/events?clubId=" + clubId);
    if (res.ok) setEvents(await res.json());
  };

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!myClub.club_id) {
      alert("Club data not loaded yet.");
      return;
    }
    if (form.date < new Date().toISOString().split("T")[0]) {
      alert("Event date cannot be in the past.");
      return;
    }
    const res = await fetch("/api/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    if (res.ok) {
      alert("Event created!");
      setForm({ title: "", description: "", date: "", venue: "", });
      loadEvents(myClub.club_id);
    }
    if (!res.ok) {
      const errorData = await res.json();
      alert("Error: " + errorData.message);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm("Delete this event?")) return;
    await fetch(`/api/events?eventId=${id}`, { method: "DELETE" });
    loadEvents(myClub.club_id);
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-indigo-600 mb-6">🎉 Manage Events ({myClub.name})</h1>

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
        <input
          type="text"
          name="venue"
          value={form.venue}
          onChange={handleChange}
          required
          className="p-2 border rounded-lg"
          placeholder="Venue"
        />
        <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg">
          Add Event
        </button>
      </form>

      <ul className="space-y-3">
        {events.map((ev) => (
          <li
            key={ev.event_id}
            className="p-4 bg-white rounded-lg shadow flex justify-between"
          >
            <div className="flex flex-col gap-2">
              <h3 className="font-semibold text-gray-800">{ev.title}</h3>
              <p className="text-sm text-gray-600">{ev.description}</p>
              <p className="text-xs text-gray-500">📅 {ev.date}</p>
              <p className="text-xs text-gray-500">📌 {ev.venue}</p>
            </div>
            <div className="">
              <button
                onClick={() => handleDelete(ev.event_id)}
                className="bg-red-500 text-white px-3 py-1 rounded-lg"
              >
                Delete
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
