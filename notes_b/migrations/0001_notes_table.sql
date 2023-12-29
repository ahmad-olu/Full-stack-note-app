-- Users Table
CREATE TABLE users (
    id VARCHAR(40) PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);

-- ApiKeys Table
CREATE TABLE api_keys (
    id VARCHAR(40) PRIMARY KEY,
    uid VARCHAR(40),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    name VARCHAR(255),
    scope VARCHAR(600),
    api_key VARCHAR(255),
    prefix VARCHAR(50),
    FOREIGN KEY (uid) REFERENCES users(id) ON DELETE CASCADE
);

-- Notes Table
CREATE TABLE notes (
    id VARCHAR(40) PRIMARY KEY,
    uid VARCHAR(40),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    title VARCHAR(255),
    description TEXT,
    FOREIGN KEY (uid) REFERENCES users(id) ON DELETE CASCADE
);