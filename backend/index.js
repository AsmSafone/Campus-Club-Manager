const express = require('express');
const poolPromise = require('./db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;
// Enable CORS for browser clients. Adjust origin as needed for production.
app.use(cors());
app.use(express.json());

// Sample route to test database connection
app.get('/test-db', async (req, res) => {
    try {
        const pool = await poolPromise;
        const [rows] = await pool.query('SELECT 1 + 1 AS solution');
        res.json({ solution: rows[0].solution });
    } catch (err) {
        res.status(500).json({ error: 'Database query failed '+err.message });
    }
});

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

        // Insert new user
        await pool.query(
            'INSERT INTO User (name, email, password, role) VALUES (?, ?, ?, ?)',
            [name, email, hashedPassword, 'Guest']
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
        
        // Active users (all except Guest)
        const [usersResult] = await pool.query("SELECT COUNT(*) as total FROM User WHERE role != 'Guest'");
        const activeUsers = usersResult[0].total;
        
        // Pending approvals (clubs without memberships or with 0 members)
        const [pendingResult] = await pool.query(`
            SELECT COUNT(DISTINCT c.club_id) as total 
            FROM Club c 
            LEFT JOIN Membership m ON c.club_id = m.club_id 
            WHERE m.membership_id IS NULL
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
            SELECT c.club_id, c.name, c.description, c.founded_date, (SELECT COUNT(*) FROM Membership m2 WHERE m2.club_id = c.club_id) as members_count
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
                    WHEN role = 'Guest' THEN 'Inactive'
                    ELSE 'Active'
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

// removed suspend endpoint; status not stored in DB

app.post('/api/clubs', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { name, description, founded_date } = req.body;
        if (!name) {
            return res.status(400).json({ message: 'Name is required' });
        }
        const [result] = await pool.query(
            'INSERT INTO Club (name, description, founded_date) VALUES (?, ?, ?)',
            [name, description || null, founded_date || null]
        );
        res.status(201).json({ club_id: result.insertId, message: 'Club created' });
    } catch (err) {
        console.error('Create club error:', err);
        res.status(500).json({ error: 'Failed to create club' });
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
            'SELECT club_id, name, description, founded_date FROM Club WHERE club_id = ?',
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
            member_count: memberCount[0].count
        });
    } catch (err) {
        console.error('Get club details error:', err);
        res.status(500).json({ error: 'Failed to fetch club details' });
    }
});

// update club details
app.put('/api/clubs/:clubId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        const { name, description, founded_date } = req.body;
        const [clubExists] = await pool.query('SELECT club_id FROM Club WHERE club_id = ?', [clubId]);
        if (clubExists.length === 0) {
            return res.status(404).json({ message: 'Club not found' });
        }
        await pool.query(
            'UPDATE Club SET name = ?, description = ?, founded_date = ? WHERE club_id = ?',
            [name, description || null, founded_date || null, clubId]
        );
        res.status(200).json({ message: 'Club updated' });
    } catch (err) {
        console.error('Update club error:', err);
        res.status(500).json({ error: 'Failed to update club' });
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
                venue,
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
       e.venue,
       c.name AS club_name
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
;
        `, [userId]);

        console.log(events);
        
        res.json(events);
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
                e.venue,
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
        const { title, description, date, time, venue } = req.body;
        
        if (!title || !date || !venue) {
            return res.status(400).json({ message: 'Title, date, and venue are required' });
        }
        
        // Combine date and time if time is provided
        let eventDateTime = date;
        if (time) {
            eventDateTime = `${date} ${time}`;
        }
        
        const [result] = await pool.query(
            'INSERT INTO Event (club_id, title, description, date, venue) VALUES (?, ?, ?, ?, ?)',
            [clubId, title, description || null, date, venue]
        );
        
        res.status(201).json({ 
            message: 'Event created successfully',
            event_id: result.insertId
        });
    } catch (err) {
        console.error('Create event error:', err);
        res.status(500).json({ error: 'Failed to create event' });
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
        const { email, name } = req.body;
        
        if (!email || !name) {
            return res.status(400).json({ message: 'Email and name are required' });
        }
        
        // Check if user exists
        const [existingUser] = await pool.query('SELECT user_id FROM User WHERE email = ?', [email]);
        let userId;
        
        if (existingUser.length > 0) {
            userId = existingUser[0].user_id;
        } else {
            return res.status(400).json({ message: 'User does not exist. Please ask the user to sign up first.' });
            // Create new user with default password
            // const hashedPassword = await bcrypt.hash('DefaultPassword123', 10);
            // const [result] = await pool.query(
            //     'INSERT INTO User (name, email, password, role) VALUES (?, ?, ?, ?)',
            //     [name, email, hashedPassword, 'Member']
            // );
            // userId = result.insertId;
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
        
        // Verify membership belongs to the club
        const [membership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE membership_id = ? AND club_id = ?',
            [membershipId, clubId]
        );
        
        if (membership.length === 0) {
            return res.status(404).json({ message: 'Membership not found' });
        }
        
        // Delete membership
        await pool.query('DELETE FROM Membership WHERE membership_id = ?', [membershipId]);
        
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

// Start server only after database is ready

// Update user role in a club
app.patch('/api/clubs/:clubId/members/:userId/role', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId, userId } = req.params;
        const { role } = req.body;
        
        // Validate role
        const validRoles = ['President', 'Secretary', 'Member'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ message: 'Invalid role' });
        }
        
        // Check if membership exists
        const [membership] = await pool.query(
            'SELECT membership_id FROM Membership WHERE club_id = ? AND user_id = ?',
            [clubId, userId]
        );
        
        if (membership.length === 0) {
            return res.status(404).json({ message: 'User is not a member of this club' });
        }

        const already_executive = await pool.query('select * from Membership WHERE user_id = ? and role != Member',[userId]);

        if(already_executive.length > 0){
            return res.status(300).json({ message: 'User is already an executive'});
        }
        
        // Update the role
        await pool.query(
            'UPDATE Membership SET role = ? WHERE club_id = ? AND user_id = ?',
            [role, clubId, userId]
        );
        
        res.json({ message: 'User role updated successfully' });
    } catch (err) {
        console.error('Update user role error:', err);
        res.status(500).json({ error: 'Failed to update user role' });
    }
});

// Get club details (for executive dashboard)
app.get('/api/executive/club/:clubId', verifyToken, async (req, res) => {
    try {
        const pool = await poolPromise;
        const { clubId } = req.params;
        
        // Get club info
        const [clubs] = await pool.query(
            'SELECT club_id, name, description, founded_date FROM Club WHERE club_id = ?',
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
        const [rows] = await pool.query('SELECT * from Notification where club_id in (select club_id from Membership where user_id = ? group by club_id)', [userId]);
        
        if (rows.length === 0) {
            return res.status(204).json({});
        }

        res.json(rows);
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
        
        // For now, return default settings
        // In a real app, you would fetch from database
        const settings = {
            pushNotifications: true,
            emailNotifications: false,
            clubAnnouncements: true,
            newEventAnnouncements: true,
            rsvpEventReminders: true,
            reminderTime: '2 hours before'
        };
        
        res.json(settings);
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
        const settings = req.body;
        
        // For now, just acknowledge the update
        // In a real app, you would save to database
        res.json({ message: 'Notification settings updated successfully' });
    } catch (err) {
        console.error('Update notification settings error:', err);
        res.status(500).json({ error: 'Failed to update notification settings' });
    }
});

// Create a new club (Admin only)
app.post('/api/admin/clubs/create', verifyToken, async (req, res) => {
    try {
        const { name, description, founded_date } = req.body;

        // Validation
        if (!name) {
            return res.status(400).json({ message: 'Club name is required' });
        }

        const pool = await poolPromise;

        // Insert new club
        const [result] = await pool.query(
            'INSERT INTO Club (name, description, founded_date) VALUES (?, ?, ?)',
            [
                name.trim(),
                description ? description.trim() : null,
                founded_date ? founded_date.trim() : null
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
        if (rows.length === 0) return res.json({ member: false });

        return res.json({ member: true, membership_id: rows[0].membership_id, role: rows[0].role });
    } catch (err) {
        console.error('Get membership error:', err);
        res.status(500).json({ error: 'Failed to check membership' });
    }
});

// Current user joins a club
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

        const [result] = await pool.query('INSERT INTO Membership (user_id, club_id, role, join_date) VALUES (?, ?, ?, ?)', [userId, clubId, 'Member', new Date().toISOString().split('T')[0]]);
        res.status(201).json({ message: 'Joined club successfully', membership_id: result.insertId });
    } catch (err) {
        console.error('Join club error:', err);
        res.status(500).json({ error: 'Failed to join club' });
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
        res.json({ message: 'Left club successfully' });
    } catch (err) {
        console.error('Leave club error:', err);
        res.status(500).json({ error: 'Failed to leave club' });
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
            `INSERT INTO Notification (club_id, title, description) VALUES (?, ?, ?)`,
            [clubId, title, description || null]
        );

        res.status(201).json({ message: 'Notification created', id: result.insertId });
    } catch (err) {
        console.error('Create notification error:', err);
        res.status(500).json({ error: 'Failed to create notification' });
    }
});

// removed event reminder endpoint (simplified notifications)