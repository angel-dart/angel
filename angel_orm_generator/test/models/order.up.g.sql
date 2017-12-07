CREATE TEMPORARY TABLE "orders" (
  "id" serial,
  "customer_id" int,
  "employee_id" int,
  "order_date" timestamp,
  "shipper_id" int,
  "created_at" timestamp,
  "updated_at" timestamp,
  PRIMARY KEY(id)
);
