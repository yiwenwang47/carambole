CREATE TABLE Word (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL,
  definition TEXT,
  exampleSentence TEXT
);
CREATE TABLE WordList (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL
);
CREATE TABLE WordListWord (
  listID TEXT NOT NULL REFERENCES WordList(id),
  wordID TEXT NOT NULL REFERENCES Word(id),
  PRIMARY KEY(listID, wordID)
);
CREATE TABLE QuestionItem (
  id TEXT PRIMARY KEY,
  wordID TEXT NOT NULL REFERENCES Word(id),
  type TEXT NOT NULL,
  prompt TEXT,
  options TEXT,       -- JSON-encoded array of 4 strings
  correctAnswer TEXT
);
CREATE TABLE ReviewStatus (
  wordID TEXT PRIMARY KEY REFERENCES Word(id),
  easeFactor REAL,
  repetitionCount INTEGER,
  intervalDays INTEGER,
  lastReviewDate TEXT,   -- ISO-8601 string
  nextReviewDate TEXT
);