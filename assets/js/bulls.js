import React, { useState, useEffect } from "react";
import {
  ch_join,
  ch_push,
  ch_reset,
  ch_start,
  ch_join_channel,
  state_update,
} from "./socket";
import socket from "./socket";

function GameOver(props) {
  let { reset, winners } = props;
  // Display secret after game is over and corresponding game over message.
  return (
    <div className="GameOver">
      <h1>Game Over!</h1>
      <h1>{"Players " + winners + " won!"}</h1>
      <p>
        <button onClick={reset}>Reset</button>
      </p>
    </div>
  );
}

function Login() {
  const [name, setName] = useState("");
  const [user, setUser] = useState("");
  const [player, setPlayer] = useState("");

  return (
    <div className="row">
      <h1>Login</h1>
      <div className="row">
        <div className="column">
          <label>Game name</label>
          <input
            type="text"
            value={name}
            onChange={(ev) => setName(ev.target.value)}
          />
        </div>
        <div className="column">
          <label>User name</label>
          <input
            type="text"
            value={user}
            onChange={(ev) => setUser(ev.target.value)}
          />
        </div>
        <div className="column">
          <label>Player?</label>
          <input
            type="checkbox"
            value="player"
            onChange={(ev) => setPlayer(ev.target.value)}
          />
        </div>
      </div>
      <div>
        <button onClick={() => ch_join_channel(name, user, player)}>
          Join
        </button>
      </div>
    </div>
  );
}

// Referenced React and Hangman code on Prof. Tuck's scratch repo.
function Play({ state }) {
  // Controlled input that requires separate useState hook
  const [guess, setGuess] = useState("");

  let {
    players,
    observers,
    secret,
    guesses,
    winners,
    bulls,
    cows,
    name,
    user,
    round,
  } = state;

  function makeGuess() {
    ch_push({ guess: guess, name: name, user: user });
    setGuess("");
  }

  // Display guesses.
  function guessesTable() {
    let results = [];
    for (var key in guesses) {
      for (let i = 0; i < guesses[key].length; i++) {
        results.push("Player: " + key + " Guess: " + guesses[key][i] + " Bulls: " + bulls[key][i] + " Cows: " + cows[key][i]);
      }
    }
    return (
      <div>
        {results.map((guess, key) => (
          <div key={key}>{guess}</div>
        ))}
      </div>
    );
  }

  // Display players.
  function playersTable() {
    let playerList = players.join(", ");
    return <div>{playerList}</div>;
  }

  // Display observers.
  function observersTable() {
    let observerList = observers.join(", ");
    return <div>{observerList}</div>;
  }

  // New game.
  function reset() {
    console.log("Resetting to a new game...");
    ch_reset();
  }

  function start_game() {
    console.log("Starting game...");
    ch_start(name, user);
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
    if (event.target.value === "" || re.test(event.target.value)) {
      setGuess(event.target.value);
    }
  }

  let body = null, gameover = null;
  let gameFinished = winners.length > 0;
  // If round is 0, game has not started.
  let gameStarted = round > 0;
  // Observers cannot guess
  let gameObserver = observers.includes(user);

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
      <p>Guesses will be evaluated and revealed every 30 seconds.</p>
      <label>
        <input
          type="text"
          value={guess}
          onChange={updateGuess}
          onKeyPress={onKeyPress}
          disabled={gameFinished || !gameStarted || gameObserver ? "disabled" : ""}
        />
        <button
          onClick={makeGuess}
          disabled={gameFinished || !gameStarted || gameObserver ? "disabled" : ""}
        >
          Guess
        </button>
      </label>
      <div>
        <button
          className="double-button"
          onClick={start_game}
          disabled={gameStarted}
        >
          Start
        </button>
        <button className="double-button" onClick={reset}>
          Reset
        </button>
      </div>
      <div>
        <label>
          Players:
          <div>{playersTable()}</div>
        </label>
        <label>
          Observers:
          <div>{observersTable()}</div>
        </label>
      </div>
    </div>
  );
  if (gameFinished) {
    let winnersList = winners.join(", ");
    gameover = <GameOver reset={reset} winners={winnersList} />;
  }

  return (
    <div className="container">
      {gameover}
      {body}
    </div>
  );
}

function Bulls() {
  const [state, setState] = useState({
    players: [],
    observers: [],
    secret: "????",
    guesses: [],
    winners: [],
    bulls: [],
    cows: [],
    name: "",
    round: 0,
    user: "",
  });
  useEffect(() => {
    ch_join(setState);
  });

  function return_login() {
    state_update({
      players: [],
      observers: [],
      secret: "????",
      guesses: [],
      winners: [],
      bulls: [],
      cows: [],
      name: "",
      round: 0,
      user: "",
    });
  }
  let body = null;

  if (state.name === "" ) {
    body = <Login />;
  } else {
    body = (
      <div className="App">
        <Play state={state} />
        <button className="return-button" onClick={return_login}>
          Return to Login
        </button>
      </div>
    );
  }

  return <div className="container">{body}</div>;
}

export default Bulls;
