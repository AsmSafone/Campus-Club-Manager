import { NextResponse } from "next/server";
import { jwtVerify } from "jose";


export async function middleware(req) {
  // ✅ 2. Get token from cookies
  const token = req.cookies.get("token")?.value;

  if (!token) {
    // Redirect to login if no token and not public
    return NextResponse.redirect(new URL("/", req.url));
  }

  try {
    // ✅ 3. Verify JWT
    const { payload } = await jwtVerify(token, new TextEncoder().encode(process.env.JWT_SECRET));
    switch (payload.role) {
      case "admin":
        return NextResponse.redirect(new URL(`/dashboard/admin`, req.url));
      case "executive":
        return NextResponse.redirect(new URL(`/dashboard/executive`, req.url));
      case "member":
        return NextResponse.redirect(new URL(`/dashboard/member`, req.url));
      case "guest":
        return NextResponse.redirect(new URL(`/dashboard/guest`, req.url));
      default:
        break;
    }
    // ✅ Allow valid request
    return NextResponse.next();
  } catch (err) {
    console.error("JWT Error:", err);
    // Invalid token — clear it and redirect to login
    const response = NextResponse.redirect(new URL("/", req.url));
    response.cookies.set("token", "", { expires: new Date(0), path: "/" });
    return response;
  }
}

// ✅ Apply middleware only to app routes
export const config = {
  matcher: [
    "/dashboard/:path*",
    "/api/:path*",
  ],
};
