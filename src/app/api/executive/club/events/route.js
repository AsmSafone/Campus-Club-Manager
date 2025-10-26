import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

// 🧠 Get all Event (anyone can view)
export async function GET(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    if (!user || user.role !== "executive")
        return new Response("Forbidden", { status: 403 });
    const { searchParams } = new URL(req.url);
    const clubId = searchParams.get("clubId");
    if (!clubId) {
        return new Response("Missing clubId parameter", { status: 400 });
    }

    const [rows] = await db.query("SELECT * FROM Event WHERE club_id = ?", [clubId]);
    return new Response(JSON.stringify(rows), { status: 200 });
}