import verifyToken from "@/lib/verifyToken";
import db from "@/lib/db";

export async function POST(req) {
    const { eventId } = await req.json();
    const user = verifyToken(req);
    if (!user || (user.role !== "member" && user.role !== "guest"))
        return new Response("Forbidden", { status: 403 });

    if (!eventId) {
        return new Response("Event ID is required", { status: 400 });
    }

    const sql = `
      INSERT INTO Registration (user_id, event_id, status)
      SELECT ?, ?, 'registered'
      FROM DUAL
      WHERE NOT EXISTS (
        SELECT 1 FROM Registration WHERE user_id = ? AND event_id = ?
      )
    `;
    const result = await db.query(sql, [user.id, eventId, user.id, eventId]);
    const affected = result?.affectedRows ?? result?.[0]?.affectedRows ?? 0;
    if (affected === 0) {
        return new Response("Already registered", { status: 409 });
    }
    return new Response("Registered successfully", { status: 200 });
}

export async function DELETE(req) {
    const { eventId } = await req.json();
    const user = verifyToken(req);
    if (!user || (user.role !== "member" && user.role !== "guest"))
        return new Response("Forbidden", { status: 403 });
    if (!eventId) {
        return new Response("Event ID is required", { status: 400 });
    }
    const sql = `DELETE FROM Registration WHERE user_id = ? AND event_id = ?`;
    const result = await db.query(sql, [user.id, eventId]);
    const affected = result?.affectedRows ?? result?.[0]?.affectedRows ?? 0;
    if (affected === 0) {
        return new Response("No registration found to cancel", { status: 404 });
    }
    return new Response("Registration cancelled successfully", { status: 200 });
}