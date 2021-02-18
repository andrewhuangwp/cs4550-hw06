import React, { useState, useEffect } from "react";
import { ch_join, ch_push, ch_reset } from "./socket";

function GameOver(props) {
  let { reset, won, secret } = props;
  // Display secret after game is over and corresponding game over message.
  return (
    <div className="GameOver">
      <h1>Game Over!</h1>
      <h1>{won ? "You won!" : "You lost!"}</h1>
      <p>{secret? "The secret number was " + secret : ""}</p>
      <p>
        <button onClick={reset}>Reset</button>
      </p>
    </div>
  );
}

// Referenced React and Hangman code on Prof. Tuck's scratch repo.
function Bulls() {
  const [state, setState] = useState({
    secret: "????",
    guesses: [],
    gameOver: false,
    bulls: [],
    cows: [],
  });

  // Controlled input that requires separate useState hook
  const [guess, setGuess] = useState("");

  let { secret, guesses, gameOver, bulls, cows } = state;

  let lives = 8 - guesses.length;

  useEffect(() => {
    ch_join(setState);
  });

  function makeGuess() {
    ch_push({ guess: guess });
    setGuess("");
  }

  // Display guesses.
  function guessesTable() {
    let results = [];
    for (let i = 0; i < guesses.length; i++) {
      results.push(guesses[i] + " Bulls: " + bulls[i] + " Cows: " + cows[i]);
    }
    return (
      <div>
        {results.map((guess, key) => (
          <div key={key}>{guess}</div>
        ))}
      </div>
    );
  }

  // New game.
  function reset() {
    console.log("Resetting to a new game...");
    ch_reset();
  }

  // If user hits enters, makes guess.
  function onKeyPress(event) {
    if (event.key === "Enter") {
      makeGuess(event.target.value);
    }
  }

  // Update guess based on user input. Only allow numerical inputs. 
  function updateGuess(event) {
    const re = /^[0-9\b]+$/;
    if (event.target.value === '' || re.test(event.target.value)) {
      setGuess(event.target.value);
   }
  }

  let body = null, gameover = null;

  body = (
    <div className="App">
      <h1>Bulls and Cows</h1>
      <p>Guess the four digit sequence. Each digit is unique.</p>
      <p>{secret}</p>
      <label>
        Guesses:
        <div>{guessesTable()}</div>
      </label>
      <p>Guesses can only be a sequence of four unique digits.</p>
      <label>
        <input
          type="text"
          value={guess}
          onChange={updateGuess}
          onKeyPress={onKeyPress}
          disabled={gameOver ? "disabled" : ""}
        />
        <button onClick={makeGuess} disabled={gameOver ? "disabled" : ""}>
          Guess
        </button>
      </label>
      <p>Remaining tries: {8 - guesses.length}</p>
      <button onClick={reset}>Reset</button>
    </div>
  );
  if (gameOver && lives > 0) {
    let secret_num = guesses[guesses.length - 1];
    gameover = <GameOver reset={reset} won={true} secret={secret_num} />;
  } else if (lives < 1) {
    gameover = <GameOver reset={reset} won={false}/>;
  }

  return <div className="container">{gameover}{body}</div>;
}

export default Bulls;
