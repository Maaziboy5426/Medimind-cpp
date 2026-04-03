const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();
const db = require('./db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

// Routes
// POST /api/posts
app.post('/api/posts', (req, res) => {
    const { userID, content, topic } = req.body;
    if (!content || !userID) return res.status(400).json({ error: 'Content and userID are required' });

    // Simple keyword filtering (Moderation)
    const banned = ['abuse', 'spam', 'dangerous health claims'];
    if (banned.some(word => content.toLowerCase().includes(word))) {
        return res.status(403).json({ error: 'Post contains prohibited content.' });
    }

    const postID = 'post_' + Date.now();
    db.run(`INSERT INTO posts (postID, userID, content, topic) VALUES (?, ?, ?, ?)`,
        [postID, userID, content, topic || 'General'], (err) => {
            if (err) return res.status(500).json({ error: err.message });

            // Fetch new post to broadcast (with user info)
            db.get(`SELECT p.*, u.username, u.avatar FROM posts p JOIN users u ON p.userID = u.userID WHERE postID = ?`, [postID], (err, row) => {
                if (row) {
                    io.emit('newPost', row); // BROADCAST TO ALL
                    res.status(201).json(row);
                } else {
                    res.status(500).json({ error: 'Failed to retrieve created post.' });
                }
            });
        });
});

// GET /api/posts - with pagination
app.get('/api/posts', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    db.all(`SELECT p.*, u.username, u.avatar 
            FROM posts p 
            JOIN users u ON p.userID = u.userID 
            ORDER BY createdAt DESC LIMIT ? OFFSET ?`, [limit, offset], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// POST /api/comments
app.post('/api/comments', (req, res) => {
    const { postID, userID, content } = req.body;
    if (!content || !userID || !postID) return res.status(400).json({ error: 'All fields required' });

    const commentID = 'comm_' + Date.now();
    db.run(`INSERT INTO comments (commentID, postID, userID, content) VALUES (?, ?, ?, ?)`,
        [commentID, postID, userID, content], (err) => {
            if (err) return res.status(500).json({ error: err.message });

            db.get(`SELECT c.*, u.username, u.avatar FROM comments c JOIN users u ON c.userID = u.userID WHERE commentID = ?`, [commentID], (err, row) => {
                if (row) {
                    io.emit('newComment', row); // BROADCAST
                    res.status(201).json(row);
                } else {
                    res.status(500).json({ error: 'Failed to retrieve created comment.' });
                }
            });
        });
});

// GET /api/posts/:postID/comments
app.get('/api/posts/:postID/comments', (req, res) => {
    db.all(`SELECT c.*, u.username, u.avatar FROM comments c JOIN users u ON c.userID = u.userID WHERE postID = ? ORDER BY createdAt ASC`, [req.params.postID], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// POST /api/like
app.post('/api/like', (req, res) => {
    const { postID, userID } = req.body;
    const likeID = 'like_' + Date.now();
    db.run(`INSERT INTO likes (likeID, postID, userID) VALUES (?, ?, ?)`, [likeID, postID, userID], (err) => {
        if (err) {
            if (err.message.includes('UNIQUE')) return res.status(400).json({ error: 'Already liked' });
            return res.status(500).json({ error: err.message });
        }

        db.run(`UPDATE posts SET likesCount = likesCount + 1 WHERE postID = ?`, [postID], (err) => {
            if (err) return res.status(500).json({ error: err.message });
            io.emit('newLike', { postID, userID }); // BROADCAST
            res.json({ success: true });
        });
    });
});

// GET /api/expert-advice
app.get('/api/expert-advice', (req, res) => {
    db.all(`SELECT * FROM expert_advice ORDER BY RANDOM() LIMIT 1`, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows[0]);
    });
});

// GET /api/groups
app.get('/api/groups', (req, res) => {
    db.all(`SELECT * FROM groups`, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Ensure User exists (Helper for demo)
app.post('/api/users/sync', (req, res) => {
    const { userID, username, avatar } = req.body;
    db.run(`INSERT OR IGNORE INTO users (userID, username, avatar) VALUES (?, ?, ?)`, [userID, username, avatar], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
    });
});

// Real-time events
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

server.listen(PORT, () => {
    console.log(`MedMind Backend running on http://localhost:${PORT}`);
});
