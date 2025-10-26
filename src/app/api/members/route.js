import db from "@/lib/db";
import verifyToken from "@/lib/verifyToken";

export async function POST(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const { clubId, userId } = await req.json();
    if (!clubId || !userId) {
        return new Response(JSON.stringify({message:"Missing required fields"}), { status: 400 });
    }
    const role = await db.query("SELECT role FROM User WHERE user_id = ?", [userId]).then(([rows]) => rows[0].role);
    await db.query("UPDATE User SET role = ? WHERE user_id = ?", [role==='guest'?'member':role, userId]);
    await db.query("INSERT INTO Membership (club_id, user_id, role, join_date) VALUES (?, ?, ?, ?)", [clubId, userId, 'member', new Date()]);
    return new Response(JSON.stringify({ message: "Member added successfully!" }), { status: 200 });
}

export async function GET(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });

    const { searchParams } = new URL(req.url);
    const clubId = searchParams.get("clubId");

    if (!clubId) {
        return new Response("Missing clubId parameter", { status: 400 });
    }

    const [rows] = await db.query("SELECT mmbr.*, usr.*, mmbr.role as membership_role, usr.role as user_role FROM Membership as mmbr JOIN User as usr ON mmbr.user_id = usr.user_id WHERE mmbr.club_id = ?", [clubId]);
    return new Response(JSON.stringify(rows), { status: 200 });
}

export async function DELETE(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("userId");
    const clubId = searchParams.get("clubId");
    if (!userId) return new Response("User ID is required", { status: 400 });
    if (!clubId) return new Response("Club ID is required", { status: 400 });
    await db.query("DELETE FROM Membership WHERE user_id = ? and club_id = ?", [userId,clubId]);

    // const [memberOrNot] = await db.query("SELECT * FROM Membership where user_id = ?", [userId]);
    
    // memberOrNot.length === 0 && await db.query("UPDATE User set role = 'guest' where user_id = ?", [userId]);
    // const role = await db.query("SELECT role FROM User WHERE user_id = ?", [userId]).then(([rows]) => rows[0].role);

    // await db.query("UPDATE User set role = ? where user_id = ?", [role,userId]);
    return new Response(JSON.stringify({ message: "User removed from club successfully!" }), { status: 200 });
}

export async function PUT(req) {
    const user = verifyToken(req);
    if (!user) return new Response("Unauthorized", { status: 401 });
    const { membershipId, userId, role } = await req.json();
    if (!membershipId || !userId || !role) {
        return new Response(JSON.stringify({message:"Missing required fields"}), { status: 400 });
    }
    // check if the user is already an executive
    const [executiveMemberOrNot] = await db.query("SELECT * FROM Membership where user_id = ? and role = 'President' or role = 'Secretary' and membership_id != ?", [userId,membershipId]);
    if(executiveMemberOrNot.length > 0 && (role === "President" || role === "Secretary")){
        return new Response(JSON.stringify({message:"User is already an executive"}), { status: 400 });
    }
    const userRole = (role === "President" || role === "Secretary") ? "executive" : "member";
    await db.query("UPDATE User SET role = ? WHERE user_id = ?", [userRole,userId]);
    await db.query("UPDATE Membership SET role = ? WHERE membership_id = ?", [role,membershipId]);
    return new Response(JSON.stringify({ message: "Member added successfully!" }), { status: 200 });
}