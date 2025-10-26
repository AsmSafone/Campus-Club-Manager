'use client';

import { useEffect, useState } from "react";

export default function ClubEvents() {
    const [events, setEvents] = useState([]);
    const [makingPayment, setMakingPayment] = useState(false)

    const loadEvents = async () => {
        fetch("/api/clubs/events")
            .then((res) => res.json())
            .then(data => setEvents(data))
            .catch(err => console.error("Failed to fetch club events:", err));
    };

    useEffect(() => {
        loadEvents();
    }, []);

    const handleEventRegister = async (eventId) => {
        setMakingPayment(true);
        payingNow(eventId);
        const res = await fetch("/api/registration", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ eventId }),
        });
        if (res.ok) {
            loadEvents();
            return;
        }
        const data = await res.text();
        alert(data);
    };

    const cancelEventRegister = async (eventId) => {
        const res = await fetch("/api/registration", {
            method: "DELETE",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ eventId }),
        });
        if (res.ok) {
            loadEvents();
            return;
        }
        const data = await res.text();
        alert(data);
    }

    return (
        <div>
            <h1 className="text-3xl font-bold text-indigo-600 mb-6">🏠 Clubs Events</h1>
            <ul className="space-y-3">
                {events.map((ev) => (
                    <li
                        key={ev.event_id}
                        className="p-4 bg-white rounded-lg shadow flex justify-between"
                    >
                        <div className="flex flex-col gap-2">
                            <h3 className="font-semibold">{ev.title}</h3>
                            <p className="text-gray-700">{ev.description}</p>
                            <p className="text-gray-700">Presented By <b>{ev.club_name}</b></p>
                            <p className="text-sm text-gray-500">📅 {ev.date}</p>
                            <p className="text-sm text-gray-500">📌 {ev.venue}</p>
                        </div>
                        <div className="">
                            {
                                ev.registration_status === 'registered' ? (
                                    <button
                                        onClick={() => cancelEventRegister(ev.event_id)}
                                        className="bg-red-500 text-white px-3 py-1 rounded-lg cursor-pointer hover:bg-red-600 transition-all"
                                    >
                                        Cancel Registration
                                    </button>
                                ) : <button
                                    onClick={() => handleEventRegister(ev.event_id)}
                                    className="bg-blue-500 text-white px-3 py-1 rounded-lg cursor-pointer hover:bg-blue-600 transition-all"
                                >
                                    Register
                                </button>
                            }
                        </div>

                    </li>
                ))}
            </ul>
        </div>
    );
}
