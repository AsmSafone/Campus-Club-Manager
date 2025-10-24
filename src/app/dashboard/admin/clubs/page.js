'use client';

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export default function ManageClubs() {
  const router = useRouter();
  const [clubs, setClubs] = useState([]);
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
          loadClubs();
        }
      } else {
        router.push("/");
      }
    };
    verifyRole();
  }, [router]);

  const loadClubs = async () => {
    const res = await fetch("/api/clubs");
    if (res.ok) {
      const data = await res.json();
      setClubs(data);
    }
  };

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    const res = await fetch("/api/clubs", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    if (res.ok) {
      setForm({ name: "", description: "" });
      loadClubs();
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-indigo-600 mb-6">🏫 Manage Clubs</h1>

      <form
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
      </form>

      <ul className="space-y-3">
        {clubs.map((club) => (
          <li
            key={club.club_id}
            className="p-4 bg-white rounded-lg shadow flex justify-between items-center"
          >
            <div>
              <h3 className="font-semibold text-gray-800">{club.name}</h3>
              <p className="text-sm text-gray-600">{club.description}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
