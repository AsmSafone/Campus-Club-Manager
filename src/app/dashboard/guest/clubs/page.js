'use client';

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export default function ManageClubs() {
    const router = useRouter();
    const [clubs, setClubs] = useState([]);
    // useEffect(() => {
    //     const verifyRole = async () => {
    //         const res = await fetch("/api/user");
    //         if (res.ok) {
    //             const data = await res.json();
    //             if (data.role !== "admin") {
    //                 alert("Access Denied: Admins Only");
    //                 router.push(`/dashboard/${data.role}`);
    //             } else {
    //                 setRole(data.role);
    //                 loadClubs();
    //             }
    //         } else {
    //             router.push("/");
    //         }
    //     };
    //     verifyRole();
    // }, [router]);

    useEffect(() => {
        loadClubs();
    }, []);

    const loadClubs = async () => {
        const res = await fetch("/api/clubs");
        if (res.ok) {
            const data = await res.json();
            console.log(data);
            
            setClubs(data);
        }
    };

    return (
        <div>
            <h1 className="text-3xl font-bold text-indigo-600 mb-6">🏫 Manage Clubs</h1>

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
                                onClick={() => fetch("/api/clubs?id=" + club.club_id, { method: "DELETE" })
                                    .then(re => re.json())
                                    .then(res => {
                                        alert(res.message);
                                        loadClubs();
                                    })
                                    .catch(err => alert(err.message))}
                                className="bg-red-500 text-white px-3 py-1 rounded-lg cursor-pointer text-sm">
                                Join Club
                            </button>
                        </div>
                    </li>
                ))}
            </ul>
        </div>
    );
}
