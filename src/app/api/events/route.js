import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

// 🧠 Get all events (anyone can view)
export async function GET() {
  const [rows] = await db.query("SELECT * FROM events");
  return new Response(JSON.stringify(rows), { status: 200 });
}

// 🏗️ Create a new event (executives only)
export async function POST(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "executive")
    return new Response("Forbidden", { status: 403 });

  const { title, description, date, club_id } = await req.json();
  await db.query(
    "INSERT INTO events (title, description, date, club_id, created_by) VALUES (?, ?, ?, ?, ?)",
    [title, description, date, club_id, user.id]
  );

  return new Response(JSON.stringify({ message: "Event created" }), { status: 201 });
}

// 🗑️ Delete event (executive only)
export async function DELETE(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "executive")
    return new Response("Forbidden", { status: 403 });

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");

  await db.query("DELETE FROM events WHERE id = ?", [id]);
  return new Response(JSON.stringify({ message: "Event deleted" }), { status: 200 });
}
