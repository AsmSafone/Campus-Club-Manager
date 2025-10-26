export async function GET(req) {
  const user = verifyToken(req);
    if (!user || user.role !== "member")
        return new Response("Forbidden", { status: 403 });
    return new Response("Email API is working", { status: 200 });
}

export async function POST(req) {
    const user = verifyToken(req);
    if (!user)
        return new Response("Forbidden", { status: 403 });
    const { to, subject, body } = await req.json(); 
    // Here you would integrate with an email service like SendGrid, Mailgun, etc.
    // integration code goes here for node js mailing service
    

    console.log(`Sending email to ${to} with subject "${subject}" and body "${body}"`);
    return new Response("Email sent successfully", { status: 200 });
}