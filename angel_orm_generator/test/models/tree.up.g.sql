CREATE TEMPORARY TABLE "trees" (
  "id" varchar,
  "rings" int UNIQUE,
  "created_at" timestamp,
  "updated_at" timestamp,
  UNIQUE(rings),
  PRIMARY KEY(id)
);
