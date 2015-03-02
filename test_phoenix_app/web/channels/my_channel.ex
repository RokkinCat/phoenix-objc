defmodule IosTestApp.MyChannel do
  use Phoenix.Channel

  def join("channel:incoming", _message, socket) do
    {:ok, socket}
  end
  def join(_priv_topic, _message, socket) do
    :ignore
  end

  def handle_in("response:event", message, socket) do
    message = Dict.put(message, "resp_value", "hoooooooo")
    broadcast socket, "response:event", message
    {:ok, socket}
  end
  def handle_in(_event, _message, socket), do: {:ok, socket}

  def handle_out(event, message, socket) do
    IO.inspect message
    reply socket, event, message
    {:ok, socket}
  end

  # # Channel - "incoming"
  # # # Topic - "event"
  # def event(socket, "event", %{"value" => value}) do
  # 	IO.puts "value: " <> value
  #   reply socket, "response:event", %{message: "Echo: " <> value}
  #   socket
  # end

  # def event(socket, "test", message) do
  # 	IO.puts "You hit test topic"
  # 	IO.puts inspect(message)
  #   socket
  # end

end