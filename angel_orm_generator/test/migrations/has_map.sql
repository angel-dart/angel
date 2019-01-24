CREATE TEMPORARY TABLE "has_maps" (
    id serial PRIMARY KEY,
    value jsonb not null,
    list jsonb not null,
    created_at timestamp,
    updated_at timestamp
);