import { NextResponse } from "next/server";

export async function POST() {
  // Clear the JWT cookie
  const response = NextResponse.json({ message: "Logged out successfully" });
  response.cookies.set("token", "", {
    httpOnly: true,
    expires: new Date(0), // immediately expires
    path: "/",
  });
  return response;
}
