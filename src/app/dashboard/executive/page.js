'use client';

export default function ExecutiveDashboard() {
  return (
    <div style={styles.container}>
      <h1>🏢 Club Executive Dashboard</h1>
      <p>Welcome, Executive! Manage your club operations here.</p>
      <ul>
        <li>📅 Create Events</li>
        <li>📊 Generate Reports</li>
        <li>📢 Notify Members</li>
      </ul>
    </div>
  );
}

const styles = {
  container: { padding: '40px', fontFamily: 'sans-serif' },
};
