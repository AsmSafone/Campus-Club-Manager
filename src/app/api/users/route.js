import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const { searchParams } = new URL(req.url);
    const clubId = searchParams.get("clubId");
    if (clubId) {
        const [rows] = await db.query("select * from User where role != 'admin' and user_id not in (select user_id from Membership where club_id = ?)", [clubId]);
        return new Response(JSON.stringify(rows), { status: 200 });
    }
    else return new Response("Missing clubId parameter", { status: 400 });
}