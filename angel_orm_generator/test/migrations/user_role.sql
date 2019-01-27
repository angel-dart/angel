CREATE TEMPORARY TABLE "role_users" (
  "id" serial PRIMARY KEY,
  "user_id" int NOT NULL,
  "role_id" int NOT NULL,
  "created_at" timestamp,
  "updated_at" timestamp
);