import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function POST(req) {
    const user = verifyToken(req);
    if (!user || user.role !== "admin")
        return new Response("Forbidden", { status: 403 });
    const { userId, clubId, role } = await req.json();
    await db.query(
        "INSERT INTO Membership (user_id, club_id, role, join_date) VALUES (?, ?, ?, ?)",
        [userId, clubId, role, new Date()]
    );
    return new Response(
        JSON.stringify({ message: `${user.name} assigned as ${role} to ${clubId}` }),
        { status: 200 }
    );
}