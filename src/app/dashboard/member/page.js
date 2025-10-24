'use client';

export default function MemberDashboard() {
  return (
    <div style={styles.container}>
      <h1>👤 Member Dashboard</h1>
      <p>Welcome, Member! Explore club activities below.</p>
      <ul>
        <li>🎟 Browse & Register for Events</li>
        <li>💳 Make Payments</li>
        <li>📅 View Upcoming Activities</li>
      </ul>
    </div>
  );
}

const styles = {
  container: { padding: '40px', fontFamily: 'sans-serif' },
};
