CREATE TEMPORARY TABLE "weird_joins" (
  "id" serial,
  "join_name" varchar(255) references unorthodoxes(name),
  PRIMARY KEY(id)
);
CREATE TEMPORARY TABLE "foos" (
  "bar" varchar(255),
  PRIMARY KEY(bar)
);
CREATE TEMPORARY TABLE "foo_pivots" (
  "weird_join_id" int references weird_joins(id),
  "foo_bar" varchar(255) references foos(bar)
);