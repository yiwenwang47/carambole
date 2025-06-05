CREATE TABLE word_lists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE words (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL,
  definition TEXT,
  example_sentence TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE word_list_words (
  word_list_id TEXT NOT NULL,
  word_id TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (word_list_id, word_id),
  FOREIGN KEY (word_list_id) REFERENCES word_lists(id),
  FOREIGN KEY (word_id) REFERENCES words(id)
);

CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  word_id TEXT NOT NULL,
  type TEXT NOT NULL,
  prompt TEXT,
  options TEXT,
  correct_answer TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (word_id) REFERENCES words(id)
);

CREATE TABLE review_status (
  word_id TEXT PRIMARY KEY REFERENCES words(id),
  ease_factor REAL,
  repetition_count INTEGER,
  interval_days INTEGER,
  last_review_date TEXT,
  next_review_date TEXT
);