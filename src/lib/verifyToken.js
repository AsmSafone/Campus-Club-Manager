import jwt from "jsonwebtoken";

export default function verifyToken(req) {
  try {
    const cookie = req.headers.get("cookie") || "";
    const token = cookie
      .split("; ")
      .find((row) => row.startsWith("token="))
      ?.split("=")[1];

    if (!token) return null;

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded; // { id, role, iat, exp }
  } catch (err) {
    return null;
  }
}
