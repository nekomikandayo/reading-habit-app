# Data Model

## User
- id
- email
- created_at

## Book
- id
- user_id
- title
- author
- created_at

## ReadingSession
- id
- user_id
- book_id
- started_at
- ended_at

## Reflection
- id
- session_id
- content (nullable)
- is_skipped (boolean)
- created_at
