defmodule Bulls.Game do
  # Attribution: Lecture 7 notes from Prof. Tuck's CS4550 section
  def new do
    %{
      secret: random_secret([]),
      guesses: [],
      gameOver: false,
      bulls: [],
      cows: []
    }
  end

  # IF guess is valid, then add to guesses and count bulls and cows.
  def guess(state, guess) do
    if validInput?(String.graphemes(guess), []) do
      %{
        state
        | guesses: state.guesses ++ [guess],
          bulls:
            state.bulls ++ [findBulls(String.graphemes(state.secret), String.graphemes(guess), 0)],
          cows:
            state.cows ++
              [findCows(String.graphemes(state.secret), String.graphemes(guess), 0, 0)]
      }
    else
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

  def view(state) do
    if Enum.member?(state.guesses, state.secret) do
      %{
        secret: "????",
        guesses: state.guesses,
        gameOver: true,
        bulls: state.bulls,
        cows: state.cows
      }
    else
      if Enum.count(state.guesses) == 8 do
        %{
          secret: "????",
          guesses: state.guesses,
          gameOver: true,
          bulls: state.bulls,
          cows: state.cows
        }
      else
        %{
          secret: "????",
          guesses: state.guesses,
          gameOver: false,
          bulls: state.bulls,
          cows: state.cows
        }
      end
    end
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
