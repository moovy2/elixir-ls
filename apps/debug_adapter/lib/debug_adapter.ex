defmodule ElixirLS.DebugAdapter do
  alias ElixirLS.Utils
  alias ElixirLS.Utils.{WireProtocol, Launch}
  alias ElixirLS.DebugAdapter.{Output, Server}

  def main do
    Application.load(:erts)
    Application.put_env(:elixir, :ansi_enabled, false)
    WireProtocol.intercept_output(&Output.debuggee_out/1, &Output.debuggee_err/1)
    Application.put_env(:elixir, :ansi_enabled, true)
    Launch.start_mix()

    if Version.match?(System.version(), ">= 1.15.0-dev") do
      # make sure that OTP debugger modules are in code path
      # without starting the app
      Mix.ensure_application!(:debugger)
    end

    {:ok, _} = Application.ensure_all_started(:debug_adapter, :permanent)

    Output.debugger_console("Started ElixirLS Debug Adapter v#{Launch.debug_adapter_version()}")
    versions = Launch.get_versions()

    Output.debugger_console(
      "ElixirLS Debug Adapter built with elixir #{versions.compile_elixir_version} on OTP #{versions.compile_otp_version}"
    )

    Output.debugger_console(
      "Running on elixir #{versions.current_elixir_version} on OTP #{versions.current_otp_version}"
    )

    Output.debugger_console(
      "Protocols are #{unless(Protocol.consolidated?(Enumerable), do: "not ", else: "")}consolidated"
    )

    Launch.limit_num_schedulers()
    warn_if_unsupported_version()

    Launch.unload_not_needed_apps([
      :nimble_parsec,
      :language_server,
      :dialyxir_vendored,
      :path_glob_vendored,
      :erlex_vendored,
      :erl2ex_vendored
    ])

    WireProtocol.stream_packets(&Server.receive_packet/1)
  end

  defp warn_if_unsupported_version do
    case Utils.MinimumVersion.check_elixir_version() do
      {:error, message} ->
        Output.debugger_important(message)
        Process.sleep(5000)
        System.halt(1)

      {:warning, message} ->
        Output.debugger_important(message)

      :ok ->
        :ok
    end

    case Utils.MinimumVersion.check_otp_version() do
      {:error, message} ->
        Output.debugger_important(message)
        Process.sleep(5000)
        System.halt(1)

      {:warning, message} ->
        Output.debugger_important(message)

      :ok ->
        :ok
    end
  end
end
