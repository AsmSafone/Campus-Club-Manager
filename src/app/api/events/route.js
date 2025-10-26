import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

// 🧠 Get all Event (anyone can view)
export async function GET() {
  const [rows] = await db.query("SELECT * FROM Event");
  return new Response(JSON.stringify(rows), { status: 200 });
}

// 🏗️ Create a new event (executives only)
export async function POST(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "executive")
    return new Response("Forbidden", { status: 403 });

  const { title, description, date, club_id, venue } = await req.json();
  if (!title || !description || !date || !club_id || !venue) {
    return new Response(JSON.stringify({ message: "Missing required fields" }), {
      status: 400,
    });
  }
  await db.query(
    "INSERT INTO Event (title, description, date, club_id, venue) VALUES (?, ?, ?, ?, ?)",
    [title, description, date, club_id, venue]
  );

  return new Response(JSON.stringify({ message: "Event created" }), { status: 201 });
}

// 🗑️ Delete event (executive only)
export async function DELETE(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "executive")
    return new Response("Forbidden", { status: 403 });

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("eventId");

  await db.query("DELETE FROM Event WHERE event_id = ?", [id]);
  return new Response(JSON.stringify({ message: "Event deleted" }), { status: 200 });
}
