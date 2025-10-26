import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const [rows] = await db.query("SELECT club.* FROM Membership as mmbr JOIN Club as club ON mmbr.club_id = club.club_id WHERE mmbr.user_id = ? and (role != 'Member' and role != 'Guest')", [user.id]);
    return new Response(JSON.stringify(rows[0]), { status: 200 });
    // const { searchParams } = new URL(req.url);
    // const executiveId = searchParams.get("executiveId");
    // if (!executiveId) {
    //     return new Response("Missing executiveId parameter", { status: 400 });
    // }
    // const [rows] = await db.query("SELECT club.* FROM Membership as mmbr JOIN Club as club ON mmbr.club_id = club.club_id WHERE mmbr.user_id = ?", [executiveId]);
    // return new Response(JSON.stringify(rows[0]), { status: 200 });
}