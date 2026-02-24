-- PostgreSQL baseline schema for Backgammon Ultra.
-- UUIDs assumed via pgcrypto extension.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    username TEXT NOT NULL UNIQUE,
    email TEXT,
    country_code CHAR(2) NOT NULL DEFAULT 'US',
    avatar_url TEXT,
    status TEXT NOT NULL DEFAULT 'active'
);

CREATE TABLE auth_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL, -- apple, game_center
    provider_user_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (provider, provider_user_id)
);

CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    doubling_cube_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    highlight_legal_moves BOOLEAN NOT NULL DEFAULT TRUE,
    forced_moves_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    pips_counter_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    board_orientation TEXT NOT NULL DEFAULT 'auto',
    preferred_match_length SMALLINT NOT NULL DEFAULT 5
);

CREATE TABLE ratings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_rating INTEGER NOT NULL DEFAULT 1500,
    ranked_matches_played INTEGER NOT NULL DEFAULT 0,
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rating_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_id UUID NOT NULL,
    season_id UUID,
    rating_before INTEGER NOT NULL,
    rating_after INTEGER NOT NULL,
    delta INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rating_history_user_created_at
    ON rating_history(user_id, created_at DESC);

CREATE TABLE seasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE season_leaderboard_entries (
    id BIGSERIAL PRIMARY KEY,
    season_id UUID NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rank INTEGER NOT NULL,
    rating INTEGER NOT NULL,
    wins INTEGER NOT NULL DEFAULT 0,
    losses INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (season_id, user_id)
);

CREATE INDEX idx_leaderboard_season_rank
    ON season_leaderboard_entries(season_id, rank ASC);

CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mode TEXT NOT NULL, -- ranked, casual, friends, local, solo
    is_ranked BOOLEAN NOT NULL DEFAULT FALSE,
    match_length SMALLINT NOT NULL,
    state TEXT NOT NULL, -- waiting, active, completed, cancelled
    season_id UUID REFERENCES seasons(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ
);

CREATE TABLE match_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    seat SMALLINT NOT NULL, -- 1 or 2
    rating_at_start INTEGER,
    rating_delta INTEGER,
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (match_id, user_id),
    UNIQUE (match_id, seat)
);

CREATE TABLE move_events (
    id BIGSERIAL PRIMARY KEY,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    seq_no INTEGER NOT NULL,
    actor_user_id UUID REFERENCES users(id),
    event_type TEXT NOT NULL, -- roll, move, cube_offer, cube_accept, resign
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (match_id, seq_no)
);

CREATE INDEX idx_move_events_match_seq
    ON move_events(match_id, seq_no ASC);

CREATE TABLE chat_events (
    id BIGSERIAL PRIMARY KEY,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_user_id UUID REFERENCES users(id),
    kind TEXT NOT NULL, -- quick_message, emoji, system
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE replay_manifests (
    match_id UUID PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
    storage_key TEXT NOT NULL,
    checksum TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'accepted',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, friend_user_id),
    CHECK (user_id <> friend_user_id)
);

CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, blocked_user_id),
    CHECK (user_id <> blocked_user_id)
);

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id),
    category TEXT NOT NULL, -- voice_abuse, cheating, harassment
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'open'
);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, achievement_id)
);

CREATE TABLE daily_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_date DATE NOT NULL,
    challenge_type TEXT NOT NULL,
    target_count INTEGER NOT NULL,
    reward_xp INTEGER NOT NULL,
    UNIQUE (challenge_date, challenge_type)
);

CREATE TABLE user_daily_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES daily_challenges(id) ON DELETE CASCADE,
    current_count INTEGER NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    UNIQUE (user_id, challenge_id)
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL, -- app_store
    product_id TEXT NOT NULL,
    status TEXT NOT NULL, -- active, expired, cancelled
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ,
    original_transaction_id TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cosmetics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL, -- board, checker, dice, frame
    display_name TEXT NOT NULL,
    price_cents INTEGER NOT NULL,
    premium_only BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cosmetic_id UUID NOT NULL REFERENCES cosmetics(id) ON DELETE CASCADE,
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT NOT NULL, -- purchase, subscription, reward
    UNIQUE (user_id, cosmetic_id)
);

CREATE TABLE fairplay_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id),
    flag_type TEXT NOT NULL,
    score NUMERIC(5, 2) NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fairplay_flags_user_created_at
    ON fairplay_flags(user_id, created_at DESC);
