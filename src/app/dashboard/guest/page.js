'use client';

export default function GuestDashboard() {
  return (
    <div style={styles.container}>
      <h1>👥 Guest View</h1>
      <p>Welcome, Guest! You can only view public events.</p>
      <ul>
        <li>👀 View Public Events</li>
        <li>ℹ️ Learn about Clubs</li>
        <li>📝 Sign Up to Join</li>
      </ul>
    </div>
  );
}

const styles = {
  container: { padding: '40px', fontFamily: 'sans-serif' },
};
