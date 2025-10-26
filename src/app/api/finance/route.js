import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function POST(req) {
    const user = verifyToken(req);
    if (!user || user.role !== "member")
        return new Response("Forbidden", { status: 403 });

    const club_id = await db.query(
        `SELECT club_id FROM Membership WHERE user_id = ?`,
        [user.id]
    ).then(([rows]) => {
        if (rows.length === 0) return null;
        return rows[0].club_id;
    });

    if (!club_id) {
        return new Response(JSON.stringify({ message: "User is not a member of any club" }), { status: 400 });
    }
    const { type, amount, date, description } = await req.json();

    if (!type || !amount || !date || !description) {
        console.log(club_id, type, amount, date, description);
        
        return new Response(JSON.stringify({ message: "Missing required fields"}), { status: 400 });
    }
    // await db.query(
    //     `INSERT INTO Payment (user_id, club_id, type, amount, date, description) VALUES (?, ?, ?, ?, ?, ?)`,
    //     [user.id, club_id, type, amount, date, description]
    // );
    return new Response(JSON.stringify({ message: "Payment recorded successfully" }), { status: 200 });
}