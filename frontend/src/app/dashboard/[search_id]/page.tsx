import DashboardClient from "@/components/DashboardClient";

export default async function DashboardPage({ params }: { params: { search_id: string } }) {
  // Await params as recommended in Next.js 15+
  const { search_id } = await params;
  return <DashboardClient searchId={search_id} />;
}
