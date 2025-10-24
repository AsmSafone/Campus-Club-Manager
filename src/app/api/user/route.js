import verifyToken from "@/lib/verifyToken";

export async function GET(req) {
  const user = verifyToken(req);
  if (!user) {
    return new Response(JSON.stringify({ loggedIn: false }), { status: 401 });
  }
  return new Response(JSON.stringify({ loggedIn: true, role: user.role }), { status: 200 });
}
