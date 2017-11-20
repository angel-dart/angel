CREATE TEMPORARY TABLE "authors" (
  "id" serial,
  "name" varchar UNIQUE,
  "created_at" timestamp,
  "updated_at" timestamp,
  UNIQUE(name),
  PRIMARY KEY(id)
);
