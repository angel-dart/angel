CREATE TEMPORARY TABLE "users" (
  "id" serial,
  "username" varchar,
  "password" varchar,
  "email" varchar,
  "created_at" timestamp,
  "updated_at" timestamp,
  "role_id" int REFERENCES roles(id),
  PRIMARY KEY(id)
);
