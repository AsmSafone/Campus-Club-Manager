import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
  const user = verifyToken(req);
  if (!user) return new Response("Unauthorized", { status: 401 });

  const [rows] = await db.query("SELECT * FROM club");
  return new Response(JSON.stringify(rows), { status: 200 });
}

export async function POST(req) {
  const user = verifyToken(req);
  if (!user || user.role !== "admin")
    return new Response("Forbidden", { status: 403 });

  const { name, description } = await req.json();
  await db.query("INSERT INTO club (name, description, founded_date) VALUES (?, ?, ?)", [
    name,
    description,
    new Date(),
  ]);

  return new Response(JSON.stringify({ message: "Club added" }), { status: 201 });
}
