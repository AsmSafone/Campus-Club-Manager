'use client';

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function Sidebar() {
    const router = useRouter();
    const [role, setRole] = useState("");

    useEffect(() => {
        const fetchRole = async () => {
            const res = await fetch("/api/user");
            if (res.ok) {
                const data = await res.json();
                setRole(data.role);
            } else {
                router.push("/");
            }
        };
        fetchRole();
    }, [router]);

    const links = [
        { name: "Dashboard Home", path: `/dashboard/${role}`, roles: ["admin", "executive", "member", "guest"] },
        { name: "Browse Clubs", path: `/dashboard/guest/clubs`, roles: ["guest"] },
        { name: "Manage Clubs", path: "/dashboard/admin/clubs", roles: ["admin"] },
        { name: "Manage Members", path: "/dashboard/admin/members", roles: ["admin"] },
        { name: "Manage Events", path: "/dashboard/executive/events", roles: ["executive"] },
        { name: "Browse Events", path: "/dashboard/guest/events", roles: ["guest"] },
        { name: "Club Events", path: "/dashboard/member/events", roles: ["member"] },
        { name: "Make Payments", path: "/dashboard/member/payments", roles: ["member"] },
    ];


    return (
        <div className="w-64 bg-white h-screen shadow-md flex flex-col p-5">
            <h2 className="text-2xl font-bold text-indigo-600 mb-8">Menu</h2>
            <ul className="space-y-2">
                {links
                    .filter(link => link.roles.includes(role))
                    .map(link => (
                        <li
                            key={link.path}
                            onClick={() => router.push(link.path)}
                            className="p-3 rounded-lg hover:bg-indigo-100 cursor-pointer text-gray-700 font-medium transition-all"
                        >
                            {link.name}
                        </li>
                    ))}
            </ul>
        </div>
    );
}
