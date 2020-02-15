CREATE TEMPORARY TABLE "cars" (
    id serial PRIMARY KEY,
    make varchar(255) NOT NULL,
    description TEXT NOT NULL,
    family_friendly BOOLEAN NOT NULL,
    recalled_at timestamp,
    created_at timestamp,
    updated_at timestamp
);