import db from "@/lib/db";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

export async function POST(req) {
  db.connect().then(() => {
    console.log("Database connected successfully.");
  }).catch((err) => { 
    console.error("Error connecting to database in login:", err);
  });

  try {
    const { email, password } = await req.json();
    const [rows] = await db.query("SELECT * FROM User WHERE email = ?", [email]);
    const user = rows[0];
    if (!user) return new Response(JSON.stringify({ error: "Invalid email" }), { status: 401 });

    const valid = await bcrypt.compare(password, user.password) || password === user.password; // For pre-hashed passwords in seed data
    if (!valid) return new Response(JSON.stringify({ error: "Invalid password" }), { status: 401 });

    const token = jwt.sign(
      { id: user.user_id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    // --- Set token as cookie ---
    const headers = new Headers();
    headers.append(
      "Set-Cookie",
      `token=${token}; Path=/; HttpOnly; Max-Age=86400; SameSite=Lax`
    );

    return new Response(JSON.stringify({ message: "Login success", role: user.role }), {
      status: 200,
      headers,
    });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "Login failed" }), { status: 500 });
  }
}
