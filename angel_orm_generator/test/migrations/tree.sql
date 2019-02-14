CREATE TEMPORARY TABLE "trees" (
  "id" serial,
  "rings" smallint UNIQUE,
  "created_at" timestamp,
  "updated_at" timestamp,
  UNIQUE(rings),
  PRIMARY KEY(id)
);