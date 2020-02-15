CREATE TEMPORARY TABLE "numbas" (
  "i" int,
  "parent" int references weird_joins(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  PRIMARY KEY(i)
);