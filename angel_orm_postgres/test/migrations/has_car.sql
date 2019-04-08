CREATE TEMPORARY TABLE "has_cars" (
    id serial PRIMARY KEY,
    type int not null,
    created_at timestamp,
    updated_at timestamp
);