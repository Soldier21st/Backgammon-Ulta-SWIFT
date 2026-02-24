# AI System (Solo Mode)

## Difficulty Ladder

10 levels are mapped to tuned profiles:

1. Beginner
2. Novice
3. Casual
4. Intermediate
5. Advanced
6. Expert
7. Master
8. Grandmaster
9. Elite
10. Champion

Each profile controls:

- randomness (mistake frequency),
- pip-race weighting,
- bear-off urgency,
- hit aggression,
- prime-building priority,
- blot safety emphasis.

## Move Generation

- Generate legal turn candidates from current dice set.
- Evaluate all legal first-move branches using deterministic rules engine.
- Keep only max-move-count candidates (Backgammon dice-usage rule).
- Enforce high-die usage when only one die can be played from non-double rolls.

## Heuristic Evaluation

Candidate board scoring combines:

- pip advantage,
- bar pressure (opponent on bar vs self on bar),
- borne-off differential,
- made-point differential,
- blot penalties,
- direct hit bonus against opponent blots.

## Selection Policy

- Sort candidates by score.
- Strong profiles (Champion/Elite) pick top move most of the time.
- Weaker profiles sample top-N candidates with higher randomness to simulate human errors.
