CREATE TEMPORARY TABLE "books" (
    id serial PRIMARY KEY,
    author_id int NOT NULL,
    partner_author_id int,
    name varchar(255),
    created_at timestamp,
    updated_at timestamp
);