import { NextResponse } from "next/server";
import { jwtVerify } from "jose";

const PUBLIC_PATHS = ["/", "/api/login", "/api/signup", "/api/events"];

export async function middleware(req) {
  const { pathname } = req.nextUrl;

  // ✅ 1. Allow all public routes
  if (PUBLIC_PATHS.some((path) => pathname.startsWith(path))) {
    return NextResponse.next();
  }

  // ✅ 2. Get token from cookies
  const token = req.cookies.get("token")?.value;

  if (!token) {
    // Redirect to login if no token and not public
    return NextResponse.redirect(new URL("/", req.url));
  }

  try {
    // ✅ 3. Verify JWT
    const { payload } = await jwtVerify(token, new TextEncoder().encode(process.env.JWT_SECRET));

    // ✅ 4. Role-based route control (optional)
    if (pathname.startsWith("/dashboard/admin") && payload.role !== "admin") {
      return NextResponse.redirect(new URL(`/dashboard/${payload.role}`, req.url));
    }
    if (pathname.startsWith("/dashboard/executive") && payload.role !== "executive") {
      return NextResponse.redirect(new URL(`/dashboard/${payload.role}`, req.url));
    }
    if (pathname.startsWith("/dashboard/member") && payload.role !== "member") {
      return NextResponse.redirect(new URL(`/dashboard/${payload.role}`, req.url));
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
