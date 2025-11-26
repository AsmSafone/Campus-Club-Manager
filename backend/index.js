const express = require('express');
const poolPromise = require('./db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const admin = require('firebase-admin');
const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase Admin SDK
// Note: In production, use a service account key file
// For now, we'll use environment variables or initialize with default credentials
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized with service account');
    } catch (err) {
        console.warn('Firebase Admin initialization failed. Push notifications will be disabled:', err.message);
    }
} else {
    console.warn('FIREBASE_SERVICE_ACCOUNT not set. Push notifications will be disabled.');
}
// Enable CORS for browser clients. Adjust origin as needed for production.
app.use(cors());
app.use(express.json());

// Sign Up endpoint
app.post('/api/auth/signup', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Validation
        if (!name || !email || !password) {
            return res.status(400).json({ message: 'Please provide name, email, and password' });
        }

        const pool = await poolPromise;

        // Check if user already exists
        const [existingUser] = await pool.query('SELECT * FROM User WHERE email = ?', [email]);
        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Email already registered' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert new user with no role assigned initially
        await pool.query(
            'INSERT INTO User (name, email, password, role) VALUES (?, ?, ?, ?)',
            [name, email, hashedPassword, null]
        );

        res.status(201).json({ message: 'User registered successfully' });
    } catch (err) {
        console.error('Sign up error:', err);
        res.status(500).json({ message: 'Server error during sign up' });
    }
});

// Sign In endpoint
app.post('/api/auth/signin', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validation
        if (!email || !password) {
            return res.status(400).json({ message: 'Please provide email and password' });
        }

        const pool = await poolPromise;

        // Find user by email
        const [users] = await pool.query('SELECT * FROM User WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        const user = users[0];

        // Check password
        const passwordMatch = await bcrypt.compare(password, user.password);
        if (!passwordMatch) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // Get user's club (first club they're a member of)
        const [memberships] = await pool.query(
            'SELECT club_id FROM Membership WHERE user_id = ? LIMIT 1',
            [user.user_id]
        );
        const clubId = memberships.length > 0 ? memberships[0].club_id : null;

        // Generate JWT token
        const token = jwt.sign(
            { userId: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'your-secret-key',
            { expiresIn: '24h' }
        );

        res.status(200).json({
            message: 'Sign in successful',
            token,
            user: {
                id: user.user_id,
                name: user.name,
                email: user.email,
                role: user.role,
                clubId: clubId
            }
        });
    } catch (err) {
        console.error('Sign in error:', err);
        res.status(500).json({ message: 'Server error during sign in' });
    }
});

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        return res.status(401).json({ message: 'No token provided' });
    }
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Invalid token' });
    }
};

// Admin Stats endpoint
app.get('/api/admin/stats', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        
        // Total clubs
        const [clubsResult] = await pool.query('SELECT COUNT(*) as total FROM Club');
        const totalClubs = clubsResult[0].total;
        
        // Active users (users with a role assigned, excluding NULL/Guest)
        const [usersResult] = await pool.query("SELECT COUNT(*) as total FROM User WHERE role IS NOT NULL AND role != 'Guest'");
        const activeUsers = usersResult[0].total;
        
        // Pending approvals (count of pending join requests)
        const [pendingResult] = await pool.query(`
            SELECT COUNT(*) as total 
            FROM ClubRequest 
            WHERE status = 'Pending'
        `);
        const pendingApprovals = pendingResult[0].total;
        
        // Event sign-ups
        const [signupsResult] = await pool.query('SELECT COUNT(*) as total FROM Registration');
        const eventSignups = signupsResult[0].total;
        
        res.json({
            totalClubs,
            activeUsers,
            pendingApprovals,
            eventSignups
        });
    } catch (err) {
        console.error('Admin stats error:', err);
        res.status(500).json({ error: 'Failed to fetch admin stats' });
    }
});

// Get all clubs with member count
app.get('/api/clubs/list', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { search, sort } = req.query;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Get clubs which have no membership for this user
        const [clubs] = await pool.query(`
            SELECT 
            c.club_id, 
            c.name, 
            c.description, 
            c.logo_url,
            c.category,
            c.founded_date, 
            (SELECT COUNT(*) FROM Membership m2 WHERE m2.club_id = c.club_id) as members_count
            FROM Club c
            LEFT JOIN Membership m ON c.club_id = m.club_id AND m.user_id = ?
            WHERE m.membership_id IS NULL
            ORDER BY c.founded_date ASC
        `, [userId]);

        res.json(clubs);
    } catch (err) {
        console.error('Get clubs error:', err);
        res.status(500).json({ error: 'Failed to fetch clubs' });
    }
});

// Get all clubs the current user is a member of
app.get('/api/users/me/clubs', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        const [clubs] = await pool.query(`
            SELECT c.club_id, c.name, c.description, c.logo_url, c.category, c.founded_date, (SELECT COUNT(*) FROM Membership m2 WHERE m2.club_id = c.club_id) as members_count
            FROM Club c 
            JOIN Membership m ON c.club_id = m.club_id
            WHERE m.user_id = ?
            ORDER BY c.name ASC
        `, [userId]);
        res.json(clubs);
    } catch (err) {
        console.error('Get my clubs error:', err);
        res.status(500).json({ error: 'Failed to fetch user clubs' });
    }
});

// Get current user profile
app.get('/api/users/me', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        const [users] = await pool.query(
            'SELECT user_id, name, email, phone, major, role FROM User WHERE user_id = ?',
            [userId]
        );
        
        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const user = users[0];
        
        // Get user's first club
        const [memberships] = await pool.query(
            'SELECT club_id FROM Membership WHERE user_id = ? LIMIT 1',
            [userId]
        );
        const clubId = memberships.length > 0 ? memberships[0].club_id : null;
        
        res.json({
            id: user.user_id,
            user_id: user.user_id,
            name: user.name,
            email: user.email,
            phone: user.phone || null,
            phone_number: user.phone || null,
            major: user.major || null,
            department: user.major || null,
            role: user.role,
            clubId: clubId,
            club_id: clubId
        });
    } catch (err) {
        console.error('Get user profile error:', err);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
});

// Update current user profile
app.patch('/api/users/me', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        const { name, email, phone, major } = req.body;
        
        // Validate required fields
        if (!name || !email) {
            return res.status(400).json({ message: 'Name and email are required' });
        }
        
        // Check if email is already taken by another user
        const [existingUsers] = await pool.query(
            'SELECT user_id FROM User WHERE email = ? AND user_id != ?',
            [email, userId]
        );
        
        if (existingUsers.length > 0) {
            return res.status(400).json({ message: 'Email already in use by another account' });
        }
        
        // Update user profile - use COALESCE to only update provided fields
        const updateFields = [];
        const updateValues = [];
        
        if (name) {
            updateFields.push('name = ?');
            updateValues.push(name);
        }
        if (email) {
            updateFields.push('email = ?');
            updateValues.push(email);
        }
        if (phone !== undefined) {
            updateFields.push('phone = ?');
            updateValues.push(phone || null);
        }
        if (major !== undefined) {
            updateFields.push('major = ?');
            updateValues.push(major || null);
        }
        
        if (updateFields.length > 0) {
            updateValues.push(userId);
            await pool.query(
                `UPDATE User SET ${updateFields.join(', ')} WHERE user_id = ?`,
                updateValues
            );
        }
        
        // Fetch updated user
        const [updatedUsers] = await pool.query(
            'SELECT user_id, name, email, phone, major, role FROM User WHERE user_id = ?',
            [userId]
        );
        
        if (updatedUsers.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const updatedUser = updatedUsers[0];
        
        // Get user's first club
        const [memberships] = await pool.query(
            'SELECT club_id FROM Membership WHERE user_id = ? LIMIT 1',
            [userId]
        );
        const clubId = memberships.length > 0 ? memberships[0].club_id : null;
        
        res.json({
            message: 'Profile updated successfully',
            user: {
                id: updatedUser.user_id,
                user_id: updatedUser.user_id,
                name: updatedUser.name,
                email: updatedUser.email,
                phone: updatedUser.phone || null,
                phone_number: updatedUser.phone || null,
                major: updatedUser.major || null,
                department: updatedUser.major || null,
                role: updatedUser.role,
                clubId: clubId,
                club_id: clubId
            }
        });
    } catch (err) {
        console.error('Update user profile error:', err);
        res.status(500).json({ error: 'Failed to update user profile' });
    }
});

// Get all users
app.get('/api/users/list', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        
        const [users] = await pool.query(`
            SELECT 
                user_id,
                name,
                email,
                role,
                CASE 
                    WHEN role IS NULL THEN 'Pending'
                    WHEN role = 'Guest' THEN 'Guest'
                    WHEN role = 'Member' THEN 'Active'
                    WHEN role = 'Executive' THEN 'Active'
                    WHEN role = 'Admin' THEN 'Active'
                    ELSE 'Unknown'
                END as status
            FROM User
            ORDER BY name
        `);
        
        res.json(users);
    } catch (err) {
        console.error('Get users error:', err);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// Delete user (admin only)
app.delete('/api/admin/users/:userId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { userId } = req.params;
        const adminUserId = req.user.userId;

        // Check if requester is admin
        const [adminCheck] = await pool.query('SELECT role FROM User WHERE user_id = ?', [adminUserId]);
        if (!adminCheck.length || adminCheck[0].role !== 'Admin') {
            return res.status(403).json({ message: 'Only admins can delete users' });
        }

        // Prevent admin from deleting themselves
        if (parseInt(userId) === adminUserId) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }

        // Check if user exists
        const [userCheck] = await pool.query('SELECT user_id, name, role FROM User WHERE user_id = ?', [userId]);
        if (!userCheck.length) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Start transaction
        await pool.query('START TRANSACTION');

        try {
            // Delete user's memberships
            await pool.query('DELETE FROM Membership WHERE user_id = ?', [userId]);

            // Delete user's club requests
            await pool.query('DELETE FROM ClubRequest WHERE user_id = ?', [userId]);

            // Delete user's event registrations
            await pool.query('DELETE FROM Registration WHERE user_id = ?', [userId]);

            // Delete user's notification settings
            await pool.query('DELETE FROM NotificationSettings WHERE user_id = ?', [userId]);

            // Finally delete the user
            await pool.query('DELETE FROM User WHERE user_id = ?', [userId]);

            await pool.query('COMMIT');

            res.json({ message: `User "${userCheck[0].name}" deleted successfully` });
        } catch (err) {
            await pool.query('ROLLBACK');
            throw err;
        }
    } catch (err) {
        console.error('Delete user error:', err);
        res.status(500).json({ error: 'Failed to delete user', details: err.message });
    }
});

// Approve club (set status by adding founder membership)
app.patch('/api/clubs/:clubId/approve', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const { userId } = req.body;
        
        // Check if club exists
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        
        // Add or update founder membership if needed
        const [existingMembership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE club_id = ? AND role = ?',
            [clubId, 'President']
        );
        
        if (existingMembership.length === 0 && userId) {
            await pool.query(
                'INSERT INTO Membership (user_id, club_id, role, join_date) VALUES (?, ?, ?, ?)',
                [userId, clubId, 'President', new Date().toISOString().split('T')[0]]
            );
        }
        res.json({ message: 'Club approved successfully' });
    } catch (err) {
        console.error('Approve club error:', err);
        res.status(500).json({ error: 'Failed to approve club' });
    }
});

// Delete club
app.delete('/api/clubs/:clubId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        // Check if club exists
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        // demote executives of this club
        await pool.query(`
            UPDATE User u
            JOIN Membership m ON u.user_id = m.user_id
            SET u.role = 'Member'
            WHERE m.club_id = ? AND m.role IN ('President', 'Secretary', 'Treasurer')
        `, [clubId]);

        // Delete the club (cascades to membership, events, registrations)
        await pool.query('DELETE FROM Club WHERE club_id = ?', [clubId]);
        return res.json({ message: 'Club deleted successfully' });
    } catch (err) {
        console.error('Delete club error:', err);
        return res.status(500).json({ error: 'Failed to delete club' });
    }
});

// Get club details (for admin/anyone)
app.get('/api/clubs/:clubId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const [clubs] = await pool.query(
            'SELECT club_id, name, description, logo_url, category, founded_date FROM Club WHERE club_id = ?',
            [clubId]
        );
        if (clubs.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        // Optionally, add member count
        const [memberCount] = await pool.query(
            'SELECT COUNT(*) as count FROM Membership WHERE club_id = ?',
            [clubId]
        );
        res.json({
            ...clubs[0],
            logo: clubs[0].logo_url,
            member_count: memberCount[0].count
        });
    } catch (err) {
        console.error('Get club details error:', err);
        res.status(500).json({ error: 'Failed to fetch club details' });
    }
});

// Reject club (delete it)
app.patch('/api/clubs/:clubId/reject', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        // Check if club exists
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        
        // Delete the club (cascades to membership, events, registrations)
        await pool.query('DELETE FROM Club WHERE club_id = ?', [clubId]);
        
        res.json({ message: 'Club rejected and deleted successfully' });
    } catch (err) {
        console.error('Reject club error:', err);
        res.status(500).json({ error: 'Failed to reject club' });
    }
});

// Get all events for a club
app.get('/api/clubs/:clubId/events', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        const [events] = await pool.query(`
            SELECT 
                event_id,
                title,
                description,
                date,
                time,
                venue,
                image_url,
                status,
                capacity,
                (SELECT COUNT(*) FROM Registration WHERE event_id = Event.event_id) as attendees
            FROM Event
            WHERE club_id = ?
            ORDER BY date DESC
            LIMIT 10
        `, [clubId]);
        res.json(events);
    } catch (err) {
        console.error('Get events error:', err);
        res.status(500).json({ error: 'Failed to fetch events' });
    }
});

// Get upcoming events for all clubs the current user is a member of (date >= today)
app.get('/api/users/me/upcoming-events', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const [events] = await pool.query(`SELECT e.event_id,
       e.title,
       e.description,
       e.date,
       e.time,
       e.venue,
       e.image_url,
       e.status,
       e.capacity,
       e.club_id,
       c.name AS club_name,
       (SELECT COUNT(*) FROM Registration r WHERE r.event_id = e.event_id) as attendees,
       (SELECT COUNT(*) FROM Registration r WHERE r.event_id = e.event_id AND r.user_id = ?) as is_registered
FROM Event e
JOIN Club c ON e.club_id = c.club_id
JOIN Membership m ON m.club_id = e.club_id
WHERE m.user_id = ?
  AND e.date >= CURDATE()
  AND e.date = (
      SELECT MIN(e2.date)
      FROM Event e2
      WHERE e2.club_id = e.club_id
        AND e2.date >= CURDATE()
  )
ORDER BY e.date ASC;
        `, [userId, userId]);

        // normalize is_registered to boolean
        const mapped = events.map(ev => ({
            ...ev,
            is_registered: (ev.is_registered && ev.is_registered > 0) ? true : false
        }));
        
        res.json(mapped);
    } catch (err) {
        console.error('Get my upcoming events error:', err);
        res.status(500).json({ error: 'Failed to fetch user upcoming events' });
    }
});

// Get events for all clubs the current user is a member of
app.get('/api/users/me/events', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const [events] = await pool.query(`
            SELECT 
                e.event_id,
                e.title,
                e.description,
                e.date,
                e.time,
                e.venue,
                e.image_url,
                e.status,
                e.capacity,
                e.club_id,
                c.name as club_name,
                (SELECT COUNT(*) FROM Registration r WHERE r.event_id = e.event_id) as attendees,
                (SELECT COUNT(*) FROM Registration r WHERE r.event_id = e.event_id AND r.user_id = ?) as is_registered
            FROM Event e
            JOIN Club c ON e.club_id = c.club_id
            WHERE e.club_id IN (SELECT club_id FROM Membership WHERE user_id = ?)
            ORDER BY e.date DESC
        `, [userId, userId]);

        // normalize is_registered to boolean
        const mapped = events.map(ev => ({
            ...ev,
            is_registered: (ev.is_registered && ev.is_registered > 0) ? true : false
        }));

        res.json(mapped);
    } catch (err) {
        console.error('Get my events error:', err);
        res.status(500).json({ error: 'Failed to fetch user events' });
    }
});

// Create a new event
app.post('/api/clubs/:clubId/events', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;
        const { title, description, date, time, venue, image_url, status, capacity } = req.body;
        
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        // Check if user is an executive of the club
        const [membership] = await pool.query(
            'SELECT role FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0 || (membership[0].role !== 'President' && membership[0].role !== 'Secretary' && membership[0].role !== 'Treasurer')) {
            return res.status(403).json({ message: 'Only club executives can create events' });
        }
        
        if (!title || !date || !venue) {
            return res.status(400).json({ message: 'Title, date, and venue are required' });
        }
        
        // Default status to 'Pending' if not provided
        const eventStatus = status || 'Pending';
        
        const [result] = await pool.query(
            'INSERT INTO Event (club_id, title, description, date, time, venue, image_url, status, capacity) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [clubId, title, description || null, date, time || null, venue, image_url || null, eventStatus, capacity || null]
        );
        
        // Automatically create a notification/announcement for the new event
        try {
            // Format date for display
            const eventDateObj = new Date(date);
            const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                          'July', 'August', 'September', 'October', 'November', 'December'];
            const eventDate = `${months[eventDateObj.getMonth()]} ${eventDateObj.getDate()}, ${eventDateObj.getFullYear()}`;
            
            const notificationTitle = `New Event: ${title}`;
            const notificationDescription = description 
                ? `${description}\n\n📅 Date: ${eventDate}\n📍 Venue: ${venue}`
                : `Join us on ${eventDate} at ${venue}!`;
            
            await pool.query(
                'INSERT INTO Notification (club_id, title, description, timestamp) VALUES (?, ?, ?, NOW())',
                [clubId, notificationTitle, notificationDescription]
            );

            // Send push notifications to all club members
            try {
                await sendPushNotificationToClubMembers(pool, clubId, notificationTitle, notificationDescription);
            } catch (pushErr) {
                console.error('Failed to send push notification for new event:', pushErr);
                // Don't fail the event creation if push notification fails
            }
        } catch (notifErr) {
            // Log error but don't fail the event creation
            console.error('Failed to create notification for event:', notifErr);
        }
        
        res.status(201).json({ 
            message: 'Event created successfully',
            event_id: result.insertId
        });
    } catch (err) {
        console.error('Create event error:', err);
        res.status(500).json({ error: 'Failed to create event' });
    }
});

// Delete an event
app.delete('/api/clubs/:clubId/events/:eventId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, eventId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;
        
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        // Check if user is an executive of the club
        const [membership] = await pool.query(
            'SELECT role FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0 || (membership[0].role !== 'President' && membership[0].role !== 'Secretary' && membership[0].role !== 'Treasurer')) {
            return res.status(403).json({ message: 'Only club executives can delete events' });
        }
        
        // Check if event exists and belongs to the club
        const [event] = await pool.query(
            'SELECT event_id FROM Event WHERE event_id = ? AND club_id = ?',
            [eventId, clubId]
        );
        
        if (event.length === 0) {
            return res.status(404).json({ message: 'Event not found or does not belong to this club' });
        }
        
        // Delete the event (cascades to registrations)
        await pool.query('DELETE FROM Event WHERE event_id = ?', [eventId]);
        
        res.json({ message: 'Event deleted successfully' });
    } catch (err) {
        console.error('Delete event error:', err);
        res.status(500).json({ error: 'Failed to delete event' });
    }
});

// Get all members for a club
app.get('/api/clubs/:clubId/members', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        // Check if club exists
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        
        // Get all members of the club with their user details
        const [members] = await pool.query(`
            SELECT 
                u.user_id,
                u.name,
                u.email,
                m.role,
                m.membership_id,
                m.join_date
            FROM Membership m
            JOIN User u ON m.user_id = u.user_id
            WHERE m.club_id = ?
            ORDER BY u.name
        `, [clubId]);
        
        res.status(200).json(members);
    } catch (err) {
        console.error('Get club members error:', err);
        res.status(500).json({ error: 'Failed to fetch club members' });
    }
});

// Add a new member to a club
app.post('/api/clubs/:clubId/members', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }
        
        // Check if user exists
        const [existingUser] = await pool.query('SELECT user_id, name FROM User WHERE email = ?', [email]);
        let userId;
        
        if (existingUser.length > 0) {
            userId = existingUser[0].user_id;
        } else {
            return res.status(400).json({ message: 'User does not exist. Please ask the user to sign up first.' });
        }
        
        // Check if already a member
        const [existingMembership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE user_id = ? AND club_id = ?',
            [userId, clubId]
        );
        
        if (existingMembership.length > 0) {
            return res.status(400).json({ message: 'User is already a member of this club' });
        }
        
        // Add to membership
        const [result] = await pool.query(
            'INSERT INTO Membership (user_id, club_id, role, join_date) VALUES (?, ?, ?, ?)',
            [userId, clubId, 'Member', new Date().toISOString().split('T')[0]]
        );
        
        res.status(201).json({ 
            message: 'Member added successfully',
            membership_id: result.insertId
        });
    } catch (err) {
        console.error('Add member error:', err);
        res.status(500).json({ error: 'Failed to add member' });
    }
});

// Update member role
app.put('/api/clubs/:clubId/members/:membershipId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, membershipId } = req.params;
        const { role } = req.body;
        
        if (!role) {
            return res.status(400).json({ message: 'Role is required' });
        }
        
        // Verify membership belongs to the club
        const [membership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE membership_id = ? AND club_id = ?',
            [membershipId, clubId]
        );
        
        if (membership.length === 0) {
            return res.status(404).json({ message: 'Membership not found' });
        }

        // Get the user id for this membership
        const [memberDetails] = await pool.query(
            'SELECT user_id FROM Membership WHERE membership_id = ?',
            [membershipId]
        );
        const userId = memberDetails[0].user_id;

        // Check whether the user holds an executive role in a different club
        // Allow changing executive roles within the same club, but disallow becoming executive if already executive in another club
        const [otherExecutiveMemberships] = await pool.query(
            'SELECT membership_id FROM Membership WHERE user_id = ? AND role != ? AND club_id != ?',
            [userId, 'Member', clubId]
        );
        if (role !== 'Member' && otherExecutiveMemberships.length > 0) {
            return res.status(400).json({ message: 'User already holds an executive role in another club' });
        }
        
        // Update membership role
        await pool.query(
            'UPDATE Membership SET role = ? WHERE membership_id = ?',
            [role, membershipId]
        );

        // Check if user is an Admin - don't change their role
        const [userRows] = await pool.query('SELECT role FROM User WHERE user_id = ?', [userId]);
        if (userRows.length > 0 && userRows[0].role === 'Admin') {
            // Admin role is preserved, don't change it
            return res.json({ message: 'Member role updated successfully' });
        }

        // Recalculate user's global role: if they have any executive memberships remain, set to Executive, otherwise Member
        const [execCountRows] = await pool.query(
            'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ? AND role != ?',
            [userId, 'Member']
        );
        const execCount = execCountRows[0].cnt || 0;
        const newUserRole = execCount > 0 ? 'Executive' : 'Member';
        await pool.query(
            'UPDATE User SET role = ? WHERE user_id = ?',
            [newUserRole, userId]
        );
        
        res.json({ message: 'Member role updated successfully' });
    } catch (err) {
        console.error('Update member role error:', err);
        res.status(500).json({ error: 'Failed to update member role' });
    }
});

// Remove member from club
app.delete('/api/clubs/:clubId/members/:membershipId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, membershipId } = req.params;
        
        // Verify membership belongs to the club and get user_id
        const [membership] = await pool.query(
            'SELECT membership_id, user_id FROM Membership WHERE membership_id = ? AND club_id = ?',
            [membershipId, clubId]
        );
        
        if (membership.length === 0) {
            return res.status(404).json({ message: 'Membership not found' });
        }
        
        const userId = membership[0].user_id;
        
        // Delete membership
        await pool.query('DELETE FROM Membership WHERE membership_id = ?', [membershipId]);
        
        // Check if user is an Admin - don't change their role
        const [userRows] = await pool.query('SELECT role FROM User WHERE user_id = ?', [userId]);
        if (userRows.length > 0 && userRows[0].role === 'Admin') {
            // Admin role is preserved, don't change it
            return res.json({ message: 'Member removed successfully' });
        }
        
        // Recalculate user's global role: if they have any executive memberships remaining, set to Executive
        // If they have any memberships, set to Member, otherwise set to Guest
        const [execCountRows] = await pool.query(
            'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ? AND role != ?',
            [userId, 'Member']
        );
        const [memberCountRows] = await pool.query(
            'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ?',
            [userId]
        );
        const execCount = execCountRows[0].cnt || 0;
        const memberCount = memberCountRows[0].cnt || 0;
        
        let newUserRole;
        if (execCount > 0) {
            newUserRole = 'Executive';
        } else if (memberCount > 0) {
            newUserRole = 'Member';
        } else {
            newUserRole = 'Guest';
        }
        
        await pool.query(
            'UPDATE User SET role = ? WHERE user_id = ?',
            [newUserRole, userId]
        );
        
        res.json({ message: 'Member removed successfully' });
    } catch (err) {
        console.error('Remove member error:', err);
        res.status(500).json({ error: 'Failed to remove member' });
    }
});

// Get financial records for a club
app.get('/api/clubs/:clubId/finance', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        const [records] = await pool.query(`
            SELECT 
                finance_id,
                type,
                amount,
                date,
                description
            FROM Finance
            WHERE club_id = ?
            ORDER BY date DESC
        `, [clubId]);
        
        // Calculate balance
        let totalIncome = 0;
        let totalExpense = 0;
        
        records.forEach(record => {
            if (record.type === 'Income') {
                totalIncome += parseFloat(record.amount);
            } else {
                totalExpense += parseFloat(record.amount);
            }
        });
        
        const balance = totalIncome - totalExpense;
        const incomePercentage = totalIncome === 0 ? 0 : (totalIncome / (totalIncome + totalExpense) * 100).toFixed(2);
        const expensePercentage = totalExpense === 0 ? 0 : (totalExpense / (totalIncome + totalExpense) * 100).toFixed(2);
        
        res.json({
            records,
            summary: {
                balance: balance.toFixed(2),
                totalIncome: totalIncome.toFixed(2),
                totalExpense: totalExpense.toFixed(2),
                incomePercentage,
                expensePercentage
            }
        });
    } catch (err) {
        console.error('Get finance error:', err);
        res.status(500).json({ error: 'Failed to fetch finance records' });
    }
});

// Add a financial record (income or expense)
app.post('/api/clubs/:clubId/finance', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const { type, amount, date, description } = req.body;
        
        if (!type || !amount || !date) {
            return res.status(400).json({ message: 'Type, amount, and date are required' });
        }
        
        if (!['Income', 'Expense'].includes(type)) {
            return res.status(400).json({ message: 'Type must be Income or Expense' });
        }
        
        const [result] = await pool.query(
            'INSERT INTO Finance (club_id, type, amount, date, description) VALUES (?, ?, ?, ?, ?)',
            [clubId, type, amount, date, description || null]
        );
        
        res.status(201).json({ 
            message: 'Financial record added successfully',
            finance_id: result.insertId
        });
    } catch (err) {
        console.error('Add finance error:', err);
        res.status(500).json({ error: 'Failed to add financial record' });
    }
});

// Get club details (for executive dashboard)
app.get('/api/executive/club/:clubId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        // Get club info
        const [clubs] = await pool.query(
            'SELECT club_id, name, description, logo_url, category, founded_date FROM Club WHERE club_id = ?',
            [clubId]
        );
        
        if (clubs.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        
        const club = clubs[0];
        
        // Get member count
        const [memberCount] = await pool.query(
            'SELECT COUNT(*) as count FROM Membership WHERE club_id = ?',
            [clubId]
        );
        
        // Get upcoming events count (events with date >= today)
        const [eventCount] = await pool.query(
            'SELECT COUNT(*) as count FROM Event WHERE club_id = ? AND date >= CURDATE()',
            [clubId]
        );
        
        // Get financial balance (income - expense)
        const [finance] = await pool.query(`
            SELECT 
                SUM(CASE WHEN type = 'Income' THEN amount ELSE 0 END) as income,
                SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) as expense
            FROM Finance WHERE club_id = ?
        `, [clubId]);
        
        const income = finance[0]?.income || 0;
        const expense = finance[0]?.expense || 0;
        const balance = income - expense;
        
        res.json({
            club_id: club.club_id,
            name: club.name,
            description: club.description,
            founded_date: club.founded_date,
            member_count: memberCount[0].count,
            upcoming_events: eventCount[0].count,
            balance: parseFloat(balance).toFixed(2)
        });
    } catch (err) {
        console.error('Get club details error:', err);
        res.status(500).json({ error: 'Failed to fetch club details' });
    }
});

// Get notifications for a user
app.get('/api/notifications', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const [rows] = await pool.query(
            `SELECT 
                n.id AS id,
                n.title,
                n.description,
                'announcement' AS type,
                NOW() AS timestamp,
                0 AS isRead,
                'campaign' AS icon
            FROM Notification n
            WHERE n.club_id IN (SELECT club_id FROM Membership WHERE user_id = ?)
            ORDER BY n.id DESC
            LIMIT 50`, [userId]
        );

        res.json(rows);
    } catch (err) {
        console.error('Get notifications error:', err);
        res.status(500).json({ error: 'Failed to fetch notifications' });
    }
});

// Get latest notification for a specific club (member only)
app.get('/api/clubs/:clubId/notifications/latest', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Check membership - only members may view club notifications
        const [membershipCheck] = await pool.query(
            'SELECT membership_id FROM Membership WHERE user_id = ? AND club_id = ?',
            [userId, clubId]
        );
        
        if (membershipCheck.length === 0) {
            return res.status(403).json({ message: 'Access denied: Not a member of this club' });
        }

        // Get latest notifications for this specific club
        const [rows] = await pool.query(
            'SELECT id, club_id, title, description, timestamp, created_at FROM Notification WHERE club_id = ? ORDER BY timestamp DESC, created_at DESC LIMIT 5',
            [clubId]
        );
        
        if (rows.length === 0) {
            return res.status(204).json([]);
        }

        // Map to include both id and notification_id for compatibility
        const mapped = rows.map(row => ({
            ...row,
            notification_id: row.id,
            date: row.timestamp || row.created_at
        }));

        res.json(mapped);
    } catch (err) {
        console.error('Get latest club notification error:', err);
        res.status(500).json({ error: 'Failed to fetch latest notification' });
    }
});

// Get notification settings for a user
app.get('/api/notifications/settings', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId;
        
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        // Try to fetch settings from database
        const [settingsRows] = await pool.query(
            'SELECT * FROM NotificationSettings WHERE user_id = ?',
            [userId]
        );
        
        if (settingsRows.length > 0) {
            const settings = settingsRows[0];
            res.json({
                email: settings.email_notifications === 1,
                email_notifications: settings.email_notifications === 1,
                push: settings.push_notifications === 1,
                push_notifications: settings.push_notifications === 1,
                pushNotifications: settings.push_notifications === 1,
                emailNotifications: settings.email_notifications === 1,
                clubAnnouncements: settings.club_announcements === 1,
                newEventAnnouncements: settings.new_event_announcements === 1,
                rsvpEventReminders: settings.rsvp_event_reminders === 1,
                reminderTime: settings.reminder_time || '2 hours before'
            });
        } else {
            // Return default settings if not found
            res.json({
                email: false,
                email_notifications: false,
                push: true,
                push_notifications: true,
            pushNotifications: true,
            emailNotifications: false,
            clubAnnouncements: true,
            newEventAnnouncements: true,
            rsvpEventReminders: true,
            reminderTime: '2 hours before'
            });
        }
    } catch (err) {
        console.error('Get notification settings error:', err);
        res.status(500).json({ error: 'Failed to fetch notification settings' });
    }
});

// Update notification settings
app.put('/api/notifications/settings', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId;
        
        if (!userId) return res.status(401).json({ message: 'Invalid user' });
        
        const {
            email,
            email_notifications,
            push,
            push_notifications,
            clubAnnouncements,
            newEventAnnouncements,
            rsvpEventReminders,
            reminderTime
        } = req.body;
        
        // Determine boolean values (handle various formats)
        const emailEnabled = email === true || email_notifications === true;
        const pushEnabled = push !== false && push_notifications !== false; // default true
        const clubAnnEnabled = clubAnnouncements !== false; // default true
        const newEventEnabled = newEventAnnouncements !== false; // default true
        const rsvpEnabled = rsvpEventReminders !== false; // default true
        
        // Check if settings exist
        const [existing] = await pool.query(
            'SELECT settings_id FROM NotificationSettings WHERE user_id = ?',
            [userId]
        );
        
        if (existing.length > 0) {
            // Update existing settings
            await pool.query(
                `UPDATE NotificationSettings SET 
                    email_notifications = ?,
                    push_notifications = ?,
                    club_announcements = ?,
                    new_event_announcements = ?,
                    rsvp_event_reminders = ?,
                    reminder_time = ?
                WHERE user_id = ?`,
                [
                    emailEnabled ? 1 : 0,
                    pushEnabled ? 1 : 0,
                    clubAnnEnabled ? 1 : 0,
                    newEventEnabled ? 1 : 0,
                    rsvpEnabled ? 1 : 0,
                    reminderTime || '2 hours before',
                    userId
                ]
            );
        } else {
            // Create new settings
            await pool.query(
                `INSERT INTO NotificationSettings 
                    (user_id, email_notifications, push_notifications, club_announcements, 
                     new_event_announcements, rsvp_event_reminders, reminder_time)
                VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [
                    userId,
                    emailEnabled ? 1 : 0,
                    pushEnabled ? 1 : 0,
                    clubAnnEnabled ? 1 : 0,
                    newEventEnabled ? 1 : 0,
                    rsvpEnabled ? 1 : 0,
                    reminderTime || '2 hours before'
                ]
            );
        }
        
        res.json({ message: 'Notification settings updated successfully' });
    } catch (err) {
        console.error('Update notification settings error:', err);
        res.status(500).json({ error: 'Failed to update notification settings' });
    }
});

// Create a new club (Admin only)
app.post('/api/admin/clubs/create', verifyToken, async (req, res) => {
    try {
        const { name, description, founded_date, logo_url, category } = req.body;

        // Validation
        if (!name) {
            return res.status(400).json({ message: 'Club name is required' });
        }

        const pool = await poolPromise;

        // Insert new club
        const [result] = await pool.query(
            'INSERT INTO Club (name, description, founded_date, logo_url, category) VALUES (?, ?, ?, ?, ?)',
            [
                name.trim(),
                description ? description.trim() : null,
                founded_date ? founded_date.trim() : null,
                logo_url || null,
                category || 'General'
            ]
        );

        res.status(201).json({
            message: 'Club created successfully',
            club_id: result.insertId,
            name: name,
            description: description || null,
            founded_date: founded_date || null
        });
    } catch (err) {
        console.error('Create club error:', err);
        res.status(500).json({ message: 'Server error during club creation', error: err.message });
    }
});

// Start server only after database is ready
poolPromise.then(() => {
    app.listen(PORT, () => {
        console.log(`Server is running on port http://localhost:${PORT}`);
    });
}).catch(err => {
    console.error('Failed to start server:', err);
    process.exit(1);
});

// Check if current user is registered for an event
app.get('/api/clubs/:clubId/events/:eventId/registration', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { eventId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const [existing] = await pool.query('SELECT reg_id FROM Registration WHERE event_id = ? AND user_id = ?', [eventId, userId]);
        res.json({ registered: existing.length > 0 });
    } catch (err) {
        console.error('Check registration error:', err);
        res.status(500).json({ error: 'Failed to check registration' });
    }
});

// Register current user to an event (club-scoped)
app.post('/api/clubs/:clubId/events/:eventId/register', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, eventId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Ensure event exists and belongs to club
        const [events] = await pool.query('SELECT event_id FROM Event WHERE event_id = ? AND club_id = ?', [eventId, clubId]);
        if (events.length === 0) return res.status(404).json({ message: 'Event not found' });

        // Check existing registration
        const [existing] = await pool.query('SELECT reg_id FROM Registration WHERE event_id = ? AND user_id = ?', [eventId, userId]);
        if (existing.length > 0) return res.status(400).json({ message: 'Already registered' });

        // Insert registration
        const [result] = await pool.query('INSERT INTO Registration (event_id, user_id, status) VALUES (?, ?, ?)', [eventId, userId, 'Registered']);
        res.status(201).json({ message: 'Registered successfully', reg_id: result.insertId });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ error: 'Failed to register for event' });
    }
});

// Register current user to an event (global endpoint fallback)
app.post('/api/events/:eventId/register', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { eventId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Ensure event exists
        const [events] = await pool.query('SELECT event_id FROM Event WHERE event_id = ?', [eventId]);
        if (events.length === 0) return res.status(404).json({ message: 'Event not found' });

        // Check existing registration
        const [existing] = await pool.query('SELECT reg_id FROM Registration WHERE event_id = ? AND user_id = ?', [eventId, userId]);
        if (existing.length > 0) return res.status(400).json({ message: 'Already registered' });

        // Insert registration
        const [result] = await pool.query('INSERT INTO Registration (event_id, user_id, status) VALUES (?, ?, ?)', [eventId, userId, 'Registered']);
        res.status(201).json({ message: 'Registered successfully', reg_id: result.insertId });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ error: 'Failed to register for event' });
    }
});

// Get membership status for the current user in a club
app.get('/api/clubs/:clubId/membership', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const [rows] = await pool.query('SELECT membership_id, role FROM Membership WHERE club_id = ? AND user_id = ?', [clubId, userId]);
        if (rows.length === 0) {
            // Check for pending request
            const [requestRows] = await pool.query(
                'SELECT request_id FROM ClubRequest WHERE club_id = ? AND user_id = ? AND status = ?',
                [clubId, userId, 'Pending']
            );
            return res.json({ 
                member: false, 
                pendingRequest: requestRows.length > 0 
            });
        }

        return res.json({ member: true, membership_id: rows[0].membership_id, role: rows[0].role, pendingRequest: false });
    } catch (err) {
        console.error('Get membership error:', err);
        res.status(500).json({ error: 'Failed to check membership' });
    }
});

// Current user requests to join a club
app.post('/api/clubs/:clubId/join', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Ensure club exists
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) return res.status(404).json({ message: 'Club not found' });

        // Check existing membership
        const [existing] = await pool.query('SELECT membership_id FROM Membership WHERE club_id = ? AND user_id = ?', [clubId, userId]);
        if (existing.length > 0) return res.status(400).json({ message: 'Already a member' });

        // Check for existing pending request
        const [existingRequest] = await pool.query(
            'SELECT request_id FROM ClubRequest WHERE club_id = ? AND user_id = ? AND status = ?',
            [clubId, userId, 'Pending']
        );
        if (existingRequest.length > 0) return res.status(400).json({ message: 'Request already pending' });

        // Update user role to Guest if not already set
        await pool.query(
            'UPDATE User SET role = ? WHERE user_id = ? AND (role IS NULL OR role = ?)',
            ['Guest', userId, 'Guest']
        );

        // Create join request
        const [result] = await pool.query(
            'INSERT INTO ClubRequest (user_id, club_id, status) VALUES (?, ?, ?)',
            [userId, clubId, 'Pending']
        );
        
        res.status(201).json({ message: 'Join request submitted successfully', request_id: result.insertId });
    } catch (err) {
        console.error('Join club request error:', err);
        res.status(500).json({ error: 'Failed to submit join request' });
    }
});

// Current user leaves a club
app.post('/api/clubs/:clubId/leave', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        await pool.query('DELETE FROM Membership WHERE club_id = ? and user_id = ?', [clubId, userId]);
        
        // Check if user is an Admin - don't change their role
        const [userRows] = await pool.query('SELECT role FROM User WHERE user_id = ?', [userId]);
        if (userRows.length > 0 && userRows[0].role === 'Admin') {
            // Admin role is preserved, don't change it
            return res.json({ message: 'Left club successfully' });
        }
        
        // Recalculate user's global role: if they have any executive memberships remaining, set to Executive
        // If they have any memberships, set to Member, otherwise set to Guest
        const [execCountRows] = await pool.query(
            'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ? AND role != ?',
            [userId, 'Member']
        );
        const [memberCountRows] = await pool.query(
            'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ?',
            [userId]
        );
        const execCount = execCountRows[0].cnt || 0;
        const memberCount = memberCountRows[0].cnt || 0;
        
        let newUserRole;
        if (execCount > 0) {
            newUserRole = 'Executive';
        } else if (memberCount > 0) {
            newUserRole = 'Member';
        } else {
            newUserRole = 'Guest';
        }
        
        await pool.query(
            'UPDATE User SET role = ? WHERE user_id = ?',
            [newUserRole, userId]
        );
        
        res.json({ message: 'Left club successfully' });
    } catch (err) {
        console.error('Leave club error:', err);
        res.status(500).json({ error: 'Failed to leave club' });
    }
});

// Get pending join requests for a club (executives only)
app.get('/api/clubs/:clubId/requests', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Check if user is an executive of the club
        const [membership] = await pool.query(
            'SELECT role FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0 || (membership[0].role !== 'President' && membership[0].role !== 'Secretary' && membership[0].role !== 'Treasurer')) {
            return res.status(403).json({ message: 'Only club executives can view requests' });
        }

        // Get pending requests with user details
        const [requests] = await pool.query(`
            SELECT 
                cr.request_id,
                cr.user_id,
                cr.status,
                cr.requested_at,
                u.name,
                u.email
            FROM ClubRequest cr
            JOIN User u ON cr.user_id = u.user_id
            WHERE cr.club_id = ? AND cr.status = 'Pending'
            ORDER BY cr.requested_at ASC
        `, [clubId]);

        res.json(requests);
    } catch (err) {
        console.error('Get club requests error:', err);
        res.status(500).json({ error: 'Failed to fetch requests' });
    }
});

// Accept a join request (executives only)
app.post('/api/clubs/:clubId/requests/:requestId/accept', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, requestId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Check if user is an executive of the club
        const [membership] = await pool.query(
            'SELECT role FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0 || (membership[0].role !== 'President' && membership[0].role !== 'Secretary' && membership[0].role !== 'Treasurer')) {
            return res.status(403).json({ message: 'Only club executives can accept requests' });
        }

        // Get the request
        const [request] = await pool.query(
            'SELECT user_id, status FROM ClubRequest WHERE request_id = ? AND club_id = ?',
            [requestId, clubId]
        );

        if (request.length === 0) {
            return res.status(404).json({ message: 'Request not found' });
        }

        if (request[0].status !== 'Pending') {
            return res.status(400).json({ message: 'Request already processed' });
        }

        const requesterUserId = request[0].user_id;

        // Check if user is already a member
        const [existingMembership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, requesterUserId]
        );

        if (existingMembership.length > 0) {
            // Delete any existing non-Pending requests for this user-club combination
            await pool.query(
                'DELETE FROM ClubRequest WHERE user_id = ? AND club_id = ? AND status != ?',
                [requesterUserId, clubId, 'Pending']
            );
            // Update request status to approved
            await pool.query(
                'UPDATE ClubRequest SET status = ? WHERE request_id = ?',
                ['Approved', requestId]
            );
            return res.status(400).json({ message: 'User is already a member' });
        }

        // Start transaction
        await pool.query('START TRANSACTION');

        try {
            // Delete any existing non-Pending requests for this user-club combination
            // This prevents unique constraint violations when updating to Approved
            await pool.query(
                'DELETE FROM ClubRequest WHERE user_id = ? AND club_id = ? AND status != ?',
                [requesterUserId, clubId, 'Pending']
            );

            // Add user to membership
            await pool.query(
                'INSERT INTO Membership (user_id, club_id, role, join_date) VALUES (?, ?, ?, ?)',
                [requesterUserId, clubId, 'Member', new Date().toISOString().split('T')[0]]
            );

            // Update request status
            await pool.query(
                'UPDATE ClubRequest SET status = ? WHERE request_id = ?',
                ['Approved', requestId]
            );

            // Update user role to Member if they have at least one membership
            const [memberCount] = await pool.query(
                'SELECT COUNT(*) as cnt FROM Membership WHERE user_id = ?',
                [requesterUserId]
            );
            
            if (memberCount[0].cnt > 0) {
                await pool.query(
                    'UPDATE User SET role = ? WHERE user_id = ?',
                    ['Member', requesterUserId]
                );
            }

            await pool.query('COMMIT');
            res.json({ message: 'Request accepted successfully' });
        } catch (err) {
            await pool.query('ROLLBACK');
            throw err;
        }
    } catch (err) {
        console.error('Accept request error:', err);
        res.status(500).json({ error: 'Failed to accept request' });
    }
});

// Reject a join request (executives only)
app.post('/api/clubs/:clubId/requests/:requestId/reject', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, requestId } = req.params;
        const userId = req.user?.userId || req.user?.user_id || null;

        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        // Check if user is an executive of the club
        const [membership] = await pool.query(
            'SELECT role FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0 || (membership[0].role !== 'President' && membership[0].role !== 'Secretary' && membership[0].role !== 'Treasurer')) {
            return res.status(403).json({ message: 'Only club executives can reject requests' });
        }

        // Get the request
        const [request] = await pool.query(
            'SELECT status FROM ClubRequest WHERE request_id = ? AND club_id = ?',
            [requestId, clubId]
        );

        if (request.length === 0) {
            return res.status(404).json({ message: 'Request not found' });
        }

        if (request[0].status !== 'Pending') {
            return res.status(400).json({ message: 'Request already processed' });
        }

        // Update request status
        await pool.query(
            'UPDATE ClubRequest SET status = ? WHERE request_id = ?',
            ['Rejected', requestId]
        );

        res.json({ message: 'Request rejected successfully' });
    } catch (err) {
        console.error('Reject request error:', err);
        res.status(500).json({ error: 'Failed to reject request' });
    }
});
// Create a simple club notification (executives only)
app.post('/api/clubs/:clubId/notifications', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const execUserId = req.user?.userId;
        const { clubId } = req.params;
        const { title, description } = req.body;
        if (!execUserId) return res.status(401).json({ message: 'Invalid user' });
        if (!title) return res.status(400).json({ message: 'Title is required' });

        const [roles] = await pool.query(
            `SELECT role FROM Membership WHERE user_id = ? AND club_id = ? LIMIT 1`,
            [execUserId, clubId]
        );
        if (roles.length === 0 || (roles[0].role !== 'President' && roles[0].role !== 'Secretary')) {
            return res.status(403).json({ message: 'Only executives can send notifications' });
        }

        const [result] = await pool.query(
            `INSERT INTO Notification (club_id, title, description, timestamp) VALUES (?, ?, ?, NOW())`,
            [clubId, title, description || null]
        );

        res.status(201).json({ message: 'Notification created', id: result.insertId });

        // Send push notifications to all club members
        try {
            await sendPushNotificationToClubMembers(pool, clubId, title, description || '');
        } catch (pushErr) {
            console.error('Failed to send push notification:', pushErr);
            // Don't fail the request if push notification fails
        }
    } catch (err) {
        console.error('Create notification error:', err);
        res.status(500).json({ error: 'Failed to create notification' });
    }
});

// Helper function to send push notifications to club members
async function sendPushNotificationToClubMembers(pool, clubId, title, body) {
    if (!admin.apps.length) {
        console.warn('Firebase Admin not initialized. Skipping push notification.');
        return;
    }

    try {
        // Get all members of the club with their device tokens and notification preferences
        const [members] = await pool.query(`
            SELECT DISTINCT
                u.user_id,
                dt.device_token,
                ns.push_notifications,
                ns.club_announcements
            FROM Membership m
            JOIN User u ON m.user_id = u.user_id
            LEFT JOIN DeviceToken dt ON u.user_id = dt.user_id
            LEFT JOIN NotificationSettings ns ON u.user_id = ns.user_id
            WHERE m.club_id = ?
            AND dt.device_token IS NOT NULL
            AND (ns.push_notifications IS NULL OR ns.push_notifications = 1)
            AND (ns.club_announcements IS NULL OR ns.club_announcements = 1)
        `, [clubId]);

        if (members.length === 0) {
            console.log('No members with push notifications enabled for club:', clubId);
            return;
        }

        // Prepare notification message
        const message = {
            notification: {
                title: title,
                body: body.length > 100 ? body.substring(0, 100) + '...' : body,
            },
            data: {
                type: 'club_announcement',
                club_id: clubId.toString(),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: 'club_notifications',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                    },
                },
            },
        };

        // Send to all device tokens
        const sendPromises = members.map(member => {
            return admin.messaging().send({
                ...message,
                token: member.device_token,
            }).catch(err => {
                console.error(`Failed to send push to user ${member.user_id}:`, err);
                // If token is invalid, remove it from database
                if (err.code === 'messaging/invalid-registration-token' || 
                    err.code === 'messaging/registration-token-not-registered') {
                    return pool.query('DELETE FROM DeviceToken WHERE device_token = ?', [member.device_token]);
                }
            });
        });

        await Promise.allSettled(sendPromises);
        console.log(`Push notifications sent to ${members.length} members for club ${clubId}`);
    } catch (err) {
        console.error('Error sending push notifications:', err);
        throw err;
    }
}

// Register device token for push notifications
app.post('/api/push/register-token', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const { device_token, platform } = req.body;

        if (!device_token) {
            return res.status(400).json({ message: 'Device token is required' });
        }

        const devicePlatform = platform || 'android';

        // Check if token already exists for this user
        const [existing] = await pool.query(
            'SELECT token_id FROM DeviceToken WHERE user_id = ? AND device_token = ?',
            [userId, device_token]
        );

        if (existing.length > 0) {
            // Update existing token
            await pool.query(
                'UPDATE DeviceToken SET platform = ?, updated_at = NOW() WHERE token_id = ?',
                [devicePlatform, existing[0].token_id]
            );
            return res.json({ message: 'Device token updated successfully' });
        } else {
            // Insert new token
            await pool.query(
                'INSERT INTO DeviceToken (user_id, device_token, platform, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())',
                [userId, device_token, devicePlatform]
            );
            return res.status(201).json({ message: 'Device token registered successfully' });
        }
    } catch (err) {
        console.error('Register device token error:', err);
        res.status(500).json({ error: 'Failed to register device token' });
    }
});

// Unregister device token
app.delete('/api/push/unregister-token', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const { device_token } = req.body;

        if (!device_token) {
            return res.status(400).json({ message: 'Device token is required' });
        }

        await pool.query(
            'DELETE FROM DeviceToken WHERE user_id = ? AND device_token = ?',
            [userId, device_token]
        );

        res.json({ message: 'Device token unregistered successfully' });
    } catch (err) {
        console.error('Unregister device token error:', err);
        res.status(500).json({ error: 'Failed to unregister device token' });
    }
});

// Send test push notification (for testing purposes)
app.post('/api/push/test', verifyToken, async (req, res) => {
    try {
        if (!admin.apps.length) {
            return res.status(503).json({ message: 'Firebase Admin not initialized' });
        }

        const pool = await poolPromise;
        const userId = req.user?.userId || req.user?.user_id;
        if (!userId) return res.status(401).json({ message: 'Invalid user' });

        const { title, body } = req.body;

        // Get user's device tokens
        const [tokens] = await pool.query(
            'SELECT device_token FROM DeviceToken WHERE user_id = ?',
            [userId]
        );

        if (tokens.length === 0) {
            return res.status(404).json({ message: 'No device tokens found for this user' });
        }

        const message = {
            notification: {
                title: title || 'Test Notification',
                body: body || 'This is a test push notification',
            },
            data: {
                type: 'test',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
        };

        const sendPromises = tokens.map(token => {
            return admin.messaging().send({
                ...message,
                token: token.device_token,
            });
        });

        await Promise.all(sendPromises);

        res.json({ message: 'Test notification sent successfully', count: tokens.length });
    } catch (err) {
        console.error('Send test notification error:', err);
        res.status(500).json({ error: 'Failed to send test notification', details: err.message });
    }
});
