const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'medmind_community.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Database connection error:', err.message);
    } else {
        console.log('Connected to MedMind Community (SQLite) Database.');
    }
});

db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
        userID TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar TEXT,
        joinedDate DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Posts table (Note: userID here refers to the user who posted)
    db.run(`CREATE TABLE IF NOT EXISTS posts (
        postID TEXT PRIMARY KEY,
        userID TEXT,
        content TEXT NOT NULL,
        topic TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        likesCount INTEGER DEFAULT 0,
        FOREIGN KEY (userID) REFERENCES users(userID)
    )`);

    // Comments table
    db.run(`CREATE TABLE IF NOT EXISTS comments (
        commentID TEXT PRIMARY KEY,
        postID TEXT,
        userID TEXT,
        content TEXT NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (postID) REFERENCES posts(postID),
        FOREIGN KEY (userID) REFERENCES users(userID)
    )`);

    // Likes table
    db.run(`CREATE TABLE IF NOT EXISTS likes (
        likeID TEXT PRIMARY KEY,
        postID TEXT,
        userID TEXT,
        UNIQUE(postID, userID),
        FOREIGN KEY (postID) REFERENCES posts(postID),
        FOREIGN KEY (userID) REFERENCES users(userID)
    )`);

    // ExpertAdvice table
    db.run(`CREATE TABLE IF NOT EXISTS expert_advice (
        adviceID TEXT PRIMARY KEY,
        title TEXT,
        content TEXT NOT NULL,
        author TEXT,
        topic TEXT
    )`);

    // Groups table
    db.run(`CREATE TABLE IF NOT EXISTS groups (
        groupID TEXT PRIMARY KEY,
        name TEXT,
        description TEXT
    )`);

    // Initial data for Expert Advice if empty
    db.get("SELECT COUNT(*) as count FROM expert_advice", (err, row) => {
        if (row && row.count === 0) {
            const expertSeed = [
                ['adv1', 'Managing Stress', 'Practice deep breathing and take short breaks. 5 minutes counts!', 'Dr. Reynolds', 'Mental Wellness'],
                ['adv2', 'Healthy Eating', 'Try replacing one sugary snack with fruit each day.', 'Nutri-Guide Sarah', 'Nutrition Tips'],
                ['adv3', 'Better Sleep', 'Avoid screens for at least 30 minutes before bed.', 'Dr. Somnos', 'Sleep Health']
            ];
            const stmt = db.prepare("INSERT INTO expert_advice (adviceID, title, content, author, topic) VALUES (?, ?, ?, ?, ?)");
            expertSeed.forEach(adv => stmt.run(adv));
            stmt.finalize();
        }
    });

    // Initial groups
    db.get("SELECT COUNT(*) as count FROM groups", (err, row) => {
        if (row && row.count === 0) {
            const groupSeed = [
                ['group1', 'Anxiety Support', 'A safe space to talk about coping with anxiety.'],
                ['group2', 'Fitness Motivation', 'Encouragement for your workout journey.'],
                ['group3', 'Chronic Illness Support', 'For those navigating health challenges.'],
                ['group4', 'Healthy Lifestyle', 'Tips for balanced living and wellbeing.']
            ];
            const stmt = db.prepare("INSERT INTO groups (groupID, name, description) VALUES (?, ?, ?)");
            groupSeed.forEach(g => stmt.run(g));
            stmt.finalize();
        }
    });

    // Dummy user
    db.run(`INSERT OR IGNORE INTO users (userID, username, avatar) VALUES ('uid1', 'Community Admin', 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin')`);
});

module.exports = db;
