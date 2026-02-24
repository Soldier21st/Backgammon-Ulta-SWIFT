# Elo Rating Logic

## Core Formula

- Expected score:
`E_A = 1 / (1 + 10 ^ ((R_B - R_A)/400))`

- Rating update:
`R'_A = R_A + K_eff * (S_A - E_A)`
where `S_A` is `1` for win, `0` for loss.

## K-factor Policy

- Provisional (`< 30` ranked matches): `K = 40`
- Established: `K = 24`
- Elite (`>= 2200`): `K = 16`

## Match Length Multiplier

- 1 point: `0.75`
- 3 points: `0.90`
- 5 points: `1.00`
- 7 points: `1.10`
- 11 points: `1.20`

Effective K:
`K_eff = K_base * matchLengthMultiplier`

## Seasonal Reset

Soft reset toward anchor 1500:
`R_new = 1500 + 0.75 * (R_old - 1500)`

## Abuse Mitigation

- Repeated opponent matches in a short window get reduced rating impact.
- Non-completed technical failures can be marked no-contest when strict criteria are met.
- Smurf/boost suspicion events feed fair-play models for manual or automated sanctions.
