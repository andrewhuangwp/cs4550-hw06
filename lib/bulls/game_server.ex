defmodule Bulls.GameServer do
  use GenServer

  alias Bulls.BackupAgent
  alias Bulls.Game

  # public interface

  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new(name)
    GenServer.start_link(
      __MODULE__,
      game,
      name: reg(name)
    )
  end

  def join(name, username, player) do
    GenServer.call(reg(name), {:join, name, username, player})
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def guess(gs, name, user) do
    GenServer.call(reg(name), {:guess, gs, name, user})
  end

  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end

  def start_game(name) do
    GenServer.call(reg(name), {:start_game, name})
  end

  # implementation

  def init(game) do
    #Process.send_after(self(), :pook, 10_000)
    {:ok, game}
  end

  def handle_call({:join, name, username, player}, _from, game) do
    game = Game.join(game, username, player)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:start_game, name}, _from, game) do
    game = Game.start(game)
    BackupAgent.put(name, game)
    schedule_evaluate()
    {:reply, game, game}
  end

  def handle_call({:reset, name}, _from, _game) do
    game = Game.new(name)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:guess, gs, name, user}, _from, game) do
    game = Game.guess(game, gs, user)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:peek, _name}, _from, game) do
    {:reply, game, game}
  end

  def schedule_evaluate() do
    Process.send_after(self(), :evaluate, 30 * 1000)
  end

  def handle_info(:evaluate, game) do
    if game.winners == [] and game.players != [] and game.round != 0 do
      game = Game.evaluate(game)
      name = "game:" <> game.name
      BackupAgent.put(game.name, game)
      if game.winners == [] and game.players != [] do
        schedule_evaluate()
      end
      BullsWeb.Endpoint.broadcast!(
      name,
      "view",
      Game.view(game, game.user))
      {:noreply, game}
    else
      {:noreply, game}
    end
  end
end