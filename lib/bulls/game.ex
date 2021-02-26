defmodule Bulls.Game do

  def start(game) do
    round = game.round + 1
    %{game | round: round}
  end

  def join(game, username, player) do
    cond do
      # If user has already joined then return state without changes.
      Enum.member?(game.players, username) || Enum.member?(game.observers, username) ->
        game
      game.round > 0 ->
        observers = game.observers ++ [username]
        %{game | observers: observers}
      player == "player" ->
        players = game.players ++ [username]
        guesses = Map.put_new(game.guesses, username, [])
        bulls = Map.put_new(game.bulls, username, [])
        cows = Map.put_new(game.cows, username, [])
        %{game | players: players, guesses: guesses, bulls: bulls, cows: cows}
      true ->
        observers = game.observers ++ [username]
        %{game | observers: observers}
    end
  end


  # Attribution: Lecture 7 notes from Prof. Tuck's CS4550 section
  def new(name) do
    %{
      players: [],
      observers: [],
      secret: random_secret([]),
      guesses: %{},
      winners: [],
      round: 0,
      bulls: %{},
      cows: %{},
      name: name,
      user: ""
    }
  end

  # IF guess is valid, then add to guesses and count bulls and cows.
  def guess(state, guess, user) do
    cond do
      Enum.member?(state.observers, user) ->
        state
      state.guesses[user] == [] ->
        if validInput?(String.graphemes(guess), []) do
          %{
            state
            | guesses: Map.put(state.guesses, user, state.guesses[user] ++ [guess]),
              bulls: Map.put(state.bulls, user, state.bulls[user] ++ [findBulls(String.graphemes(state.secret), String.graphemes(guess), 0)]),
              cows: Map.put(state.cows, user, state.cows[user] ++ [findCows(String.graphemes(state.secret), String.graphemes(guess), 0, 0)])
          }
        else
          state
        end
      Enum.count(state.guesses[user]) == state.round ->
        state
      validInput?(String.graphemes(guess), []) ->
        %{
          state
          | guesses: Map.put(state.guesses, user, state.guesses[user] ++ [guess]),
            bulls: Map.put(state.bulls, user, state.bulls[user] ++ [findBulls(String.graphemes(state.secret), String.graphemes(guess), 0)]),
            cows: Map.put(state.cows, user, state.cows[user] ++ [findCows(String.graphemes(state.secret), String.graphemes(guess), 0, 0)])
        }
      true ->
        state
    end
  end

  # Determine how many digits are in the right place.
  def findBulls(secret, guess, counter) do
    cond do
      Enum.count(guess) == 0 ->
        counter

      hd(secret) == hd(guess) ->
        findBulls(tl(secret), tl(guess), counter + 1)

      true ->
        findBulls(tl(secret), tl(guess), counter)
    end
  end

  def findCows(secret, guess, counter, index) do
    cond do
      Enum.count(guess) == 0 ->
        counter

      Enum.member?(secret, hd(guess)) and Enum.at(secret, index) != hd(guess) ->
        findCows(secret, tl(guess), counter + 1, index + 1)

      true ->
        findCows(secret, tl(guess), counter, index + 1)
    end
  end

  def random_secret(secret_num) do
    random_num = Enum.random(0..9)

    cond do
      Enum.member?(secret_num, random_num) ->
        random_secret(secret_num)

      Enum.count(secret_num) < 3 ->
        random_secret(secret_num ++ [random_num])

      Enum.count(secret_num) < 4 ->
        Enum.join(secret_num ++ [random_num], "")

      true ->
        IO.puts("Something went wrong while generating secret.")
    end
  end

  def isSecret?(secret, guesses) do
    if Enum.member?(guesses, secret) do
      secret
    else
      "????"
    end
  end

  # Evaluate guesses by checking if any player has guessed correctly and add pass if player hasn't guessed yet.
  def evaluate(state) do
    guesses = Enum.into(Enum.map(state.guesses, fn {k, v} -> if (length(v) < state.round) do {k, v ++ ["pass"]} else {k,v} end end), %{})
    bulls = Enum.into(Enum.map(state.bulls, fn {k, v} -> if (length(v) < state.round) do {k, v ++ [0]} else {k,v} end end), %{})
    cows = Enum.into(Enum.map(state.cows, fn {k, v} -> if (length(v) < state.round) do {k, v ++ [0]} else {k,v} end end), %{})
    round = state.round + 1
    winners = findWinners(state.bulls)
    %{state | guesses: guesses, round: round, bulls: bulls, cows: cows, winners: winners}
  end

  def findWinners(bulls) do
    Enum.map(bulls, fn {k, v} -> if (Enum.member?(v, 4)) do k end end)
    |> Enum.filter(&(&1 != nil))
  end

  def delete_last(delete_list) do
    if delete_list == [] do
      delete_list
    else
      delete_list 
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
    end
  end

  def view(state, user) do
    guesses = Enum.into(Enum.map(state.guesses, fn {k, v} -> if (length(v) == 0 || length(v) < state.round) do {k, v} else {k, delete_last(v)} end end), %{})
    bulls = Enum.into(Enum.map(state.bulls, fn {k, v} -> if (length(v) == 0 || length(v) < state.round) do {k, v} else {k, delete_last(v)} end end), %{})
    cows = Enum.into(Enum.map(state.cows, fn {k, v} -> if (length(v) == 0 || length(v) < state.round) do {k, v} else {k, delete_last(v)} end end), %{})
    %{
      secret: "????",
      players: state.players,
      observers: state.observers,
      guesses: guesses,
      bulls: bulls,
      cows: cows,
      name: state.name,
      round: state.round,
      winners: state.winners,
      user: user
    }
  end

  def view(state) do
    %{
      secret: "????",
      players: state.players,
      observers: state.observers,
      guesses: state.guesses,
      bulls: state.bulls,
      cows: state.cows,
      name: state.name,
      round: state.round,
      winners: state.winners
    }
  end

  def validInput?(guess, used) do
    cond do
      Enum.count(guess) + Enum.count(used) != 4 ->
        false

      Enum.count(guess) == 0 ->
        true

      Enum.member?(used, hd(guess)) ->
        false

      true ->
        validInput?(tl(guess), used ++ [hd(guess)])
    end
  end
end
