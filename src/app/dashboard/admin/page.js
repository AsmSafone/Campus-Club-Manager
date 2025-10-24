export default function AdminDashboard() {
  return (
    <div className="max-w-4xl mx-auto bg-white shadow-md rounded-2xl p-6">
      <h1 className="text-3xl font-bold text-indigo-600 mb-4">👑 Admin Dashboard</h1>
      <ul className="space-y-3 text-gray-800">
        <li className="p-3 bg-indigo-50 rounded-lg">📋 Manage Clubs</li>
        <li className="p-3 bg-indigo-50 rounded-lg">💰 Log Transactions</li>
        <li className="p-3 bg-indigo-50 rounded-lg">🧑‍💻 Manage Executives & Members</li>
      </ul>
    </div>
  );
}
