'use client';

import { useEffect, useState } from "react";

export default function ClubEvents() {
    const [events, setEvents] = useState([]);
    const [makingPayment, setMakingPayment] = useState(false)
    const [myClubs, setMyClubs] = useState([]);

    // const loadEvents = async () => {
    //     fetch("/api/clubs/events")
    //         .then((res) => res.json())
    //         .then(data => setEvents(data))
    //         .catch(err => console.error("Failed to fetch club events:", err));
    // };

    // useEffect(() => {
    //     loadEvents();
    // }, []);

    // const handleEventRegister = async (eventId) => {
    //     setMakingPayment(true);
    //     payingNow(eventId);
    //     const res = await fetch("/api/registration", {
    //         method: "POST",
    //         headers: { "Content-Type": "application/json" },
    //         body: JSON.stringify({ eventId }),
    //     });
    //     if (res.ok) {
    //         loadEvents();
    //         return;
    //     }
    //     const data = await res.text();
    //     alert(data);
    // };

    // const cancelEventRegister = async (eventId) => {
    //     const res = await fetch("/api/registration", {
    //         method: "DELETE",
    //         headers: { "Content-Type": "application/json" },
    //         body: JSON.stringify({ eventId }),
    //     });
    //     if (res.ok) {
    //         loadEvents();
    //         return;
    //     }
    //     const data = await res.text();
    //     alert(data);
    // }

    const loadMyClub = async () => {
        fetch("/api/clubs/myclub").then((res) => res.json())
            .then(data => setMyClubs(data))
            .catch(err => console.error("Failed to fetch my clubs:", err));
    };

    useEffect(() => {
        loadMyClub();
    }, []);

    return (
        <div>
            <h1 className="text-3xl font-bold text-indigo-600 mb-6">💲 Payments</h1>
            <div className="max-w-4xl mx-auto p-6">
                <form onSubmit={async (e) => {
                    e.preventDefault();
                    const formData = new FormData(e.target);
                    const data = {
                        club_id: formData.get('club_id'),
                        type: formData.get('type'),
                        amount: parseFloat(formData.get('amount')),
                        date: formData.get('date'),
                        description: formData.get('description')
                    };

                    try {
                        const res = await fetch('/api/finance', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(data)
                        });

                        if (res.ok) {
                            res.json().then(data => console.log(data)).catch(err => console.error(err.message || err));

                            // // Send confirmation email
                            // await fetch('/api/email', {
                            //     method: 'POST',
                            //     headers: { 'Content-Type': 'application/json' },
                            //     body: JSON.stringify({
                            //         subject: `Payment ${data.type} Recorded`,
                            //         content: `A ${data.type} of $${data.amount} has been recorded for ${data.description}`
                            //     })
                            // });
                            // alert('Payment recorded successfully');
                            // e.target.reset();
                        } else {
                            console.log();

                            alert(await res.json().then(data => data.message).catch(() => 'Failed to record payment'));
                        }
                    } catch (error) {
                        console.error('Error:', error.message || error);
                        alert('An error occurred');
                    }
                }}>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Club</label>
                            <select name="type" required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-4">
                                {myClubs.map(mc => <option key={mc.club_id} defaultValue={mc.club_id}>{mc.name}</option>)}
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Type</label>
                            <select name="type" required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-4">
                                <option defaultChecked defaultValue="income">Income</option>
                                <option defaultValue="expense">Expense</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Amount</label>
                            <input type="number" name="amount" step="0.01" required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-4" defaultValue={1500} />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Date</label>
                            <input type="date" name="date" required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-4" defaultValue={"2060-12-30"} />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Description</label>
                            <textarea name="description" required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-4" defaultValue={"this is for registration (dummy)!"}></textarea>
                        </div>
                        <button type="submit" className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700">
                            Confirm Payment
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
