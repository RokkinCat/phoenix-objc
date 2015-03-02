defmodule IosTestApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :ios_test_app

  # Serve at "/" the given assets from "priv/static" directory
  plug Plug.Static,
    at: "/", from: :ios_test_app,
    only: ~w(css images js favicon.ico robots.txt)

  plug Plug.Logger

  # Code reloading will only work if the :code_reloader key of
  # the :phoenix application is set to true in your config file.
  plug Phoenix.CodeReloader

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_ios_test_app_key",
    signing_salt: "SjIt6F6s",
    encryption_salt: "zS1a9UcS"

  plug :router, IosTestApp.Router
end
