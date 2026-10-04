#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
secret_number=$(( RANDOM % 1000 + 1 ))
guesses=0

echo "Enter your username:"
read -r username

escaped_username=${username//\'/\'\'}
user_data=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username = '$escaped_username'")

if [[ -n $user_data ]]; then
  IFS='|' read -r games_played best_game <<< "$user_data"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
else
  echo "Welcome, $username! It looks like this is your first time here."
fi

echo "Guess the secret number between 1 and 1000:"
read -r guess

while true; do
  if ! [[ $guess =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read -r guess
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_number=$((10#${guess#+}))
  fi

  ((guesses += 1))

  if (( guess_number == secret_number )); then
    break
  elif (( guess_number > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi

  read -r guess
done

$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$escaped_username', 1, $guesses) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = CASE WHEN users.best_game IS NULL OR EXCLUDED.best_game < users.best_game THEN EXCLUDED.best_game ELSE users.best_game END" >/dev/null

echo "You guessed it in $guesses tries. The secret number was $secret_number. Nice job!"