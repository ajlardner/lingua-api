# Lingua API

A language learning API with spaced repetition (SM-2 algorithm) built in Ruby on Rails.

By [Aidan Lardner](https://www.github.com/ajlardner)

## Features

- **Spaced Repetition**: SM-2 algorithm for optimal review scheduling
- **Flashcard Management**: Create and organize flashcards in decks
- **Study Sessions**: Get due cards for review, track progress
- **JWT Authentication**: Secure token-based auth

## API Endpoints

### Authentication

```
POST /auth/register    # Create account
POST /auth/login       # Get JWT token
GET  /auth/me          # Current user info
```

### Decks

```
GET    /decks          # List user's decks
POST   /decks          # Create deck
GET    /decks/:id      # Show deck with flashcards
PATCH  /decks/:id      # Update deck
DELETE /decks/:id      # Delete deck
GET    /decks/:id/study # Get due cards for study session
```

### Flashcards

```
GET    /decks/:deck_id/flashcards      # List cards in deck
GET    /decks/:deck_id/flashcards/due  # List due cards only
POST   /decks/:deck_id/flashcards      # Create flashcard
GET    /decks/:deck_id/flashcards/:id  # Show flashcard
PATCH  /decks/:deck_id/flashcards/:id  # Update flashcard
DELETE /decks/:deck_id/flashcards/:id  # Delete flashcard
POST   /decks/:deck_id/flashcards/:id/review  # Record review (quality 0-5)
```

## SM-2 Algorithm

The review endpoint uses the SM-2 spaced repetition algorithm:

- **Quality 0-2**: Failed review, interval resets to 0
- **Quality 3-5**: Successful review, interval increases
- First success: 1 day
- Second success: 6 days
- Subsequent: `interval × ease_factor`

Ease factor adjusts based on review quality (minimum 1.3).

## Development

The files in the `.devcontainer` folder contain everything needed to get the development version of the app up and running in VSCode devcontainers or Github codespaces.

```bash
# Start development environment
docker-compose up

# Run tests
rails test

# Start server
rails server
```

## Tech Stack

- Ruby on Rails 8.1 (API mode)
- PostgreSQL
- JWT authentication
- SM-2 spaced repetition
