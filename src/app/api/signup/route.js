import db from "@/lib/db";
import bcrypt from "bcrypt";

export async function POST(req) {
    const { name, email, password } = await req.json();

    if (!process.env.MYSQL_HOST || !process.env.MYSQL_USER || !process.env.MYSQL_DATABASE) {
        return new Response(JSON.stringify({ error: "Server configuration error" }), { status: 500 });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const [existing] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    if (existing.length) {
        return new Response(JSON.stringify({ error: "User already exists" }), { status: 400 });
    }

    await db.query("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", [
        name,
        email,
        hashedPassword,
    ]);

    return new Response(JSON.stringify({ message: "User registered successfully" }), { status: 201 });
}
