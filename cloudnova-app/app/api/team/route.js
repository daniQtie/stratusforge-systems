export const dynamic = "force-dynamic";

const members = [
  { name: "Agustin", role: "Enterprise Cloud Architect" },
];

export async function GET() {
  return Response.json({ members, count: members.length });
}
