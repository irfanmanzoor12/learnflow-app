-- LearnFlow Database Schema
-- Run against the 'learnflow' database

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'teacher')),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    agent TEXT NOT NULL,
    message TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS progress (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    module TEXT NOT NULL,
    topic TEXT NOT NULL,
    mastery INT DEFAULT 0 CHECK (mastery >= 0 AND mastery <= 100),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, module, topic)
);

CREATE TABLE IF NOT EXISTS code_submissions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    code TEXT NOT NULL,
    stdout TEXT DEFAULT '',
    stderr TEXT DEFAULT '',
    exit_code INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Seed a demo student
INSERT INTO users (name, role) VALUES ('Maya', 'student') ON CONFLICT DO NOTHING;
INSERT INTO users (name, role) VALUES ('Mr. Rodriguez', 'teacher') ON CONFLICT DO NOTHING;

-- Seed initial progress
INSERT INTO progress (user_id, module, topic, mastery) VALUES
    (1, 'Basics', 'Variables', 85),
    (1, 'Basics', 'Data Types', 70),
    (1, 'Control Flow', 'For Loops', 60),
    (1, 'Control Flow', 'While Loops', 40),
    (1, 'Data Structures', 'Lists', 30)
ON CONFLICT (user_id, module, topic) DO NOTHING;
