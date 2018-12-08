CREATE TEMPORARY TABLE "user_roles" (
  "id" serial PRIMARY KEY,
  "user_id" int NOT NULL,
  "role_id" int NOT NULL,
  "created_at" timestamp,
  "updated_at" timestamp
);