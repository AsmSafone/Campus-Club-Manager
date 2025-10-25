'use client';

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export default function ManageMembers() {
    const router = useRouter();
    const [members, setMembers] = useState([]);
    const [form, setForm] = useState({ name: "", description: "" });
    const [role, setRole] = useState("");

    useEffect(() => {
        const verifyRole = async () => {
            const res = await fetch("/api/user");
            if (res.ok) {
                const data = await res.json();
                if (data.role !== "admin") {
                    alert("Access Denied: Admins Only");
                    router.push(`/dashboard/${data.role}`);
                } else {
                    setRole(data.role);
                    loadMembers();
                }
            } else {
                router.push("/");
            }
        };
        verifyRole();
    }, [router]);

    const loadMembers = async () => {
        const res = await fetch("/api/members");
        if (res.ok) {
            const data = await res.json();
            setMembers(data);
        }
    };

    const handleChange = (e) =>
        setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        const res = await fetch("/api/members", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(form),
        });
        if (res.ok) {
            setForm({ name: "", description: "" });
            loadMembers();
        }
    };

    return (
        <div>
            <h1 className="text-3xl font-bold text-indigo-600 mb-6">🏫 Manage Members</h1>

            {/* <form
                onSubmit={handleSubmit}
                className="flex gap-3 mb-8 items-center"
            >
                <input
                    name="name"
                    placeholder="Club Name"
                    value={form.name}
                    onChange={handleChange}
                    required
                    className="p-2 border rounded-lg w-1/3"
                />
                <input
                    name="description"
                    placeholder="Description"
                    value={form.description}
                    onChange={handleChange}
                    required
                    className="p-2 border rounded-lg w-1/3"
                />
                <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg cursor-pointer" type="submit">
                    Add Club
                </button>
            </form> */}

            <ul className="space-y-3">
                {members.map((member) => (
                    <li
                        key={member.user_id}
                        className="p-4 bg-white rounded-lg shadow flex justify-between items-center"
                    >
                        <div className="flex flex-col">
                            <h3 className="font-semibold text-gray-800">{member.name}</h3>
                            <p className="text-sm text-gray-600">{member.email}</p>
                            <p className="text-sm text-gray-600">{member.role}</p>
                        </div>
                        <div className="flex gap-2">
                            {/* <a className="bg-yellow-500 text-white px-3 py-1 rounded-lg cursor-pointer text-sm" href="/dashboard/">
                                Edit
                            </a> */}
                            <button onClick={() => fetch("/api/members?id="+member.user_id, { method: "DELETE" }).then(re => re.json()).then(res => alert(res.message),loadMembers()).catch(err => alert(err.message))} className="bg-red-500 text-white px-3 py-1 rounded-lg cursor-pointer text-sm">
                                Delete
                            </button>
                        </div>
                    </li>
                ))}
            </ul>
        </div>
    );
}
