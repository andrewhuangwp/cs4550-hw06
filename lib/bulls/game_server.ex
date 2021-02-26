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

  def join(name, username) do
    GenServer.call(reg(name), {:join, name, username})
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def guess(name, num) do
    GenServer.call(reg(name), {:guess, name, num})
  end

  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end

  # implementation

  def init(game) do
    #Process.send_after(self(), :pook, 10_000)
    {:ok, game}
  end

  def handle_call({:join, name, username}, _from, game) do
    game = Game.join(game, username)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:reset, name}, _from, game) do
    game = Game.new(name)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:guess, name, letter}, _from, game) do
    game = Game.guess(game, letter)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:peek, _name}, _from, game) do
    {:reply, game, game}
  end

  def handle_info(:pook, game) do
    game = Game.guess(game, "q")
    BullsWeb.Endpoint.broadcast!(
      "game:7",
      "view",
      Game.view(game, ""))
    {:noreply, game}
  end
end