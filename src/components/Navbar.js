'use client';

import { useRouter, usePathname } from "next/navigation";
import { useState, useEffect } from "react";

export default function Navbar() {
  const router = useRouter();
  const pathname = usePathname();
  const [userRole, setUserRole] = useState("");

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const res = await fetch("/api/user");
        if (res.ok) {
          const data = await res.json();
          setUserRole(data.role);
        } else {
          router.push("/");
        }
      } catch {
        router.push("/");
      }
    };
    fetchUser();
  }, [router]);

  const handleLogout = async () => {
    await fetch("/api/logout", { method: "POST" });
    router.push("/");
  };

  return (
    <nav className="bg-white shadow-md py-3 px-6 flex justify-between items-center">
      <h1
        onClick={() => router.push(`/dashboard/${userRole}`)}
        className="text-xl font-bold text-indigo-600 cursor-pointer"
      >
        Campus Club Manager
      </h1>

      <div className="flex items-center gap-6">
        <span className="text-gray-700 capitalize">{userRole}</span>
        <button
          onClick={handleLogout}
          className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-all"
        >
          Logout
        </button>
      </div>
    </nav>
  );
}
