import verifyToken from "@/lib/verifyToken";
import db from "@/lib/db";

export async function GET(req) {
  const user = verifyToken(req);
  if (!user) {
    return new Response(JSON.stringify({ loggedIn: false }), { status: 401 });
  }
  const [rows] = await db.query("SELECT * FROM User where user_id = ?", [user.id]);
  delete rows[0].password;
  return new Response(JSON.stringify({ loggedIn: true, role: user.role, user_id: user.id, user: rows[0] }), { status: 200 });
}
