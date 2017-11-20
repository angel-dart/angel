CREATE TEMPORARY TABLE "books" (
  "id" serial,
  "name" varchar,
  "created_at" timestamp,
  "updated_at" timestamp,
  "author_id" int REFERENCES authors(id) ON DELETE CASCADE,
  PRIMARY KEY(id)
);
