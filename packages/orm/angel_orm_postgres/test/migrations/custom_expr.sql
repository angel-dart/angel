CREATE TEMPORARY TABLE "numbers" (
    id serial PRIMARY KEY,
    created_at timestamp,
    updated_at timestamp
);

CREATE TEMPORARY TABLE "alphabets" (
    id serial PRIMARY KEY,
    value TEXT,
    numbers_id int,
    created_at timestamp,
    updated_at timestamp
);