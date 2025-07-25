defmodule ElixirLS.DebugAdapter.Protocol.Basic do
  @moduledoc """
  Macros for Debug Adapter Protocol messages

  These macros can be used for pattern matching or for creating messages corresponding to the
  request, response, and event types as specified in VS Code debug protocol.
  """

  defmacro request(seq, command) do
    quote do
      %{"type" => "request", "command" => unquote(command), "seq" => unquote(seq)}
    end
  end

  defmacro request(seq, command, arguments) do
    quote do
      %{
        "type" => "request",
        "command" => unquote(command),
        "seq" => unquote(seq),
        "arguments" => unquote(arguments)
      }
    end
  end

  defmacro response(seq, request_seq, command) do
    quote do
      %{
        "type" => "response",
        "command" => unquote(command),
        "seq" => unquote(seq),
        "request_seq" => unquote(request_seq),
        "success" => true
      }
    end
  end

  defmacro response(seq, request_seq, command, body) do
    quote do
      %{
        "type" => "response",
        "command" => unquote(command),
        "seq" => unquote(seq),
        "request_seq" => unquote(request_seq),
        "success" => true,
        "body" => unquote(body)
      }
    end
  end

  defmacro error_response(
             seq,
             request_seq,
             command,
             message,
             format,
             variables,
             send_telemetry,
             show_user
           ) do
    message_value = Macro.expand_once(message, __CALLER__)

    error_id =
      case message_value do
        value when is_binary(value) -> ElixirLS.DebugAdapter.ErrorDictionary.code(value)
        _ -> quote(do: ElixirLS.DebugAdapter.ErrorDictionary.code(unquote(message)))
      end

    quote do
      %{
        "type" => "response",
        "command" => unquote(command),
        "seq" => unquote(seq),
        "request_seq" => unquote(request_seq),
        "success" => false,
        "message" => unquote(message),
        "body" => %{
          "error" => %{
            "id" => unquote(error_id),
            "format" => unquote(format),
            "variables" => unquote(variables),
            "showUser" => unquote(show_user),
            "sendTelemetry" => unquote(send_telemetry)
          }
        }
      }
    end
  end

  defmacro event(seq, event, body) do
    quote do
      %{
        "type" => "event",
        "event" => unquote(event),
        "body" => unquote(body),
        "seq" => unquote(seq)
      }
    end
  end

  defmacro event(seq, event) do
    quote do
      %{
        "type" => "event",
        "event" => unquote(event),
        "seq" => unquote(seq)
      }
    end
  end
end
