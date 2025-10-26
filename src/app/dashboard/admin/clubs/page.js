'use client';

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export default function ManageClubs() {
    const router = useRouter();
    const [clubs, setClubs] = useState([]);
    const [form, setForm] = useState({ name: "", description: "" });
    const [role, setRole] = useState("");
    const [userModel, setUserModel] = useState(false)
    const [memberModel, setMemberModel] = useState(false);
    const [selectedClub, setSelectedClub] = useState(null);
    const [users, setUsers] = useState([]);
    const [members, setMembers] = useState([]);

    useEffect(() => {
        const verifyRole = async () => {
            const res = await fetch("/api/user");
            if (res.ok) {
                const data = await res.json();
                if (data.role !== "admin") {
                    alert("Access Denied: Admins Only");
                    router.push(`/dashboard/${data.role}`);
                } else {
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

    const loadMembers = async (club) => {
        const res = await fetch("/api/members" + "?clubId=" + club.club_id);
        if (res.ok) {
            const data = await res.json();
            setMembers(data);
        }
    };

    const loadUsers = async () => {
        const res = await fetch("/api/users" + "?clubId=" + selectedClub.club_id);
        if (res.ok) {
            const data = await res.json();
            setUsers(data);
        }
    };

    const handleManageClub = (club) => {
        setSelectedClub(club);
        setMemberModel(true);
        loadMembers(club);
    };

    const addMemberToclub = async (userId) => {
        const res = await fetch("/api/members/", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                clubId: selectedClub.club_id,
                userId: userId,
            }),
        });
        if (res.ok) {
            alert("Member added successfully");
            loadMembers(selectedClub);
            loadUsers();
        }
        if (!res.ok) {
            const data = await res.json();
            alert(data.message);
        }
    };

    const removeMemberFromClub = async (userId) => {
        const res = await fetch("/api/members?userId=" + userId + "&clubId=" + selectedClub.club_id, {
            method: "DELETE",
        });
        if (res.ok) {
            alert("Member removed successfully");
            loadMembers(selectedClub);
            loadUsers();
        }
        if (!res.ok) {
            const data = await res.json();
            alert(data.message);
        }
    };

    const updateMembershipRole = async (role,member) => {
        const res = await fetch("/api/members/", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                membershipId: member.membership_id,
                userId: member.user_id,
                role: role
            }),
        });
        if (res.ok) {
            alert("Membership role updated successfully");
            loadMembers(selectedClub);
        }
        if (!res.ok) {
            const data = await res.json();
            alert(data.message);
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
                        <div className="flex flex-col">
                            <h3 className="font-semibold text-gray-800">{club.name}</h3>
                            <p className="text-sm text-gray-600">{club.description}</p>
                        </div>
                        <div className="flex gap-2">
                            <button
                                onClick={() => handleManageClub(club)}
                                className="bg-yellow-500 text-white px-3 py-1 rounded-lg cursor-pointer text-sm">
                                Manage
                            </button>
                            <button
                                onClick={() => fetch("/api/clubs?id=" + club.club_id, { method: "DELETE" })
                                    .then(re => re.json())
                                    .then(res => {
                                        alert(res.message);
                                        loadClubs();
                                    })
                                    .catch(err => alert(err.message))}
                                className="bg-red-500 text-white px-3 py-1 rounded-lg cursor-pointer text-sm">
                                Delete
                            </button>
                        </div>
                    </li>
                ))}
            </ul>

            {memberModel && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
                    <div className="bg-white p-6 rounded-lg w-1/2">
                        <div className="flex justify-between items-center">
                            <h2 className="text-xl font-bold mb-4">Manage Executives - {selectedClub.name}</h2>
                            <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg cursor-pointer" onClick={async () => { await loadUsers(); setUserModel(!userModel); }}>Add Members</button>
                        </div>
                        <div className="max-h-96 overflow-y-auto">
                            {members.map(member => (
                                <div key={member.user_id} className="flex justify-between items-center p-2 border-b">
                                    <span>{member.name} ({member.email}) ({member.user_role})</span>
                                    <div className="flex gap-2">
                                        <select className="p-2 rounded" onChange={(e) => e.target.value && updateMembershipRole(e.target.value, member)} value={member.membership_role}>
                                            <option value="">{member.membership_role}</option>
                                            <option value="President">President</option>
                                            <option value="Secretary">Secretary</option>
                                            <option value="Member">Member</option>
                                        </select>
                                        <button className="bg-red-600 text-white px-4 py-2 rounded-lg cursor-pointer" onClick={()=>removeMemberFromClub(member.user_id)}>Remove</button>
                                    </div>
                                </div>
                            ))}
                        </div>
                        <button
                            onClick={() => setMemberModel(false)}
                            className="mt-4 bg-gray-500 text-white px-4 py-2 rounded-lg"
                        >
                            Close
                        </button>
                    </div>
                </div>
            )
            }

            {
                userModel && (
                    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
                        <div className="bg-white p-6 rounded-lg w-1/2">
                            <div className="flex justify-between items-center">
                                <h2 className="text-xl font-bold mb-4">Add Members - {selectedClub.name}</h2>
                            </div>
                            <div className="max-h-96 overflow-y-auto">
                                {users.map(user => (
                                    <div key={user.user_id} className="flex justify-between items-center p-2 border-b">
                                        <span>{user.name} ({user.email})</span>
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => addMemberToclub(user.user_id)}
                                                className="bg-indigo-600 text-white px-3 py-1 rounded-lg text-sm"
                                            >
                                                Add
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <button
                                onClick={() => setUserModel(false)}
                                className="mt-4 bg-gray-500 text-white px-4 py-2 rounded-lg"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                )
            }
        </div >
    );
}
