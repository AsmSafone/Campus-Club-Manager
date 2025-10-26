import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
  const user = verifyToken(req);
  if (!user) return new Response("Unauthorized", { status: 401 });

  const [rows] = await db.query("SELECT * FROM club WHERE club_id IN (SELECT club_id FROM Membership WHERE user_id = ?)", [user.id]);
  return new Response(JSON.stringify(rows), { status: 200 });
}