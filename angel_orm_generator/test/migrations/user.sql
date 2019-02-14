CREATE TEMPORARY TABLE "users" (
  "id" serial PRIMARY KEY,
  "username" varchar(255),
  "password" varchar(255),
  "email" varchar(255),
  "created_at" timestamp,
  "updated_at" timestamp
);