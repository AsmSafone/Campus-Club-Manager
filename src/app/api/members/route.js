import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });

    const [rows] = await db.query("SELECT * FROM User");
    return new Response(JSON.stringify(rows), { status: 200 });
}

export async function DELETE(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("id");
    if (!userId) return new Response("User ID is required", { status: 400 });
    await db.query("DELETE FROM User WHERE user_id = ?", [userId]);
    return new Response(JSON.stringify({ message: "User deleted successfully!" }), { status: 200 });
}
