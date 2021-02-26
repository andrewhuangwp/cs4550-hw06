defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.Game
  alias Bulls.GameServer

  @impl true
  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      GameServer.start(name)
      socket = socket
      |> assign(:name, name)
      |> assign(:user, "")
      game = GameServer.peek(name)
      view = Game.view(game)
      {:ok, view, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Login to game as user.
  @impl true
  def handle_in("login", %{"user" => user, "name" => name, "player" => player}, socket) do
    view = GameServer.join(name, user, player)
    |> Game.view(user)
    {:reply, {:ok, view}, socket}
  end

  # Start the game.
  @impl true
  def handle_in("start", %{"name" => name, "user" => user}, socket) do
    view = GameServer.start_game(name)
    |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  # Handle guess messages.
  @impl true
  def handle_in("guess", %{"guess" => gs, "name" => name, "user" => user}, socket) do
    view = GameServer.guess(gs, name, user)
    |> Game.view(user)
    {:reply, {:ok, view}, socket}
  end

  # Handle reset messages.
  @impl true
  def handle_in("reset", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name] # game name
    |> GameServer.reset()
    |> Game.view()
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  intercept ["view"]

  @impl true
  def handle_out("view", msg, socket) do
    user = socket.assigns[:user]
    push(socket, "view", msg)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
