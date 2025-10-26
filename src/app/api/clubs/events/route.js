import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

// 🧠 Get clubs Events (members can view)
export async function GET(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "member")
    return new Response("Forbidden", { status: 403 });

  const [rows] = await db.query(`
    SELECT 
        e.*, 
        c.name AS club_name, 
        c.description AS club_description,
        r.reg_id,
        r.status AS registration_status
    FROM 
        Event e 
    JOIN 
        Club c ON e.club_id = c.club_id 
    LEFT JOIN 
        Registration r ON e.event_id = r.event_id AND r.user_id = ?
    WHERE 
        e.club_id IN (
            SELECT club_id 
            FROM Membership 
            WHERE user_id = ?
        )
    ORDER BY
        e.date DESC`,
    [user.id, user.id]
  );
  // db.query(`
  //   SELECT e.*, c.name as club_name, c.description as club_description 
  //   FROM Event e 
  //   JOIN Club c ON e.club_id = c.club_id 
  //   WHERE e.club_id IN (
  //     SELECT club_id 
  //     FROM Membership 
  //     WHERE user_id = ?
  //   )`, [user.id]);

  return new Response(JSON.stringify(rows), { status: 200 });
}