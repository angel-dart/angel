CREATE TEMPORARY TABLE "songs" (
  "id" serial,
  "weird_join_id" int references weird_joins(id),
  "title" varchar(255),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  PRIMARY KEY(id)
);