# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Mcp.ToolsMetaTest do
  @moduledoc """
  Tests for _meta field support in MCP tools.
  """
  use AshAi.RepoCase, async: false
  import Plug.{Conn, Test}

  alias AshAi.Mcp.Router
  alias AshAi.Test.Music

  @opts_with_meta [tools: [:list_artists_with_meta], otp_app: :ash_ai]
  @opts_without_meta [tools: [:list_artists], otp_app: :ash_ai]

  describe "tools/list with _meta" do
    test "includes _meta field when tool has meta defined" do
      session_id = initialize_and_get_session_id(@opts_with_meta)

      response = list_tools(session_id, @opts_with_meta)
      body = decode_response(response)

      assert response.status == 200
      assert body["jsonrpc"] == "2.0"
      assert is_list(body["result"]["tools"])

      tool = Enum.find(body["result"]["tools"], &(&1["name"] == "list_artists_with_meta"))
      assert tool

      # Verify _meta field is present and contains expected metadata
      assert tool["_meta"]
      assert tool["_meta"]["openai/outputTemplate"] == "ui://widget/artist-list.html"
      assert tool["_meta"]["openai/toolInvocation/invoking"] == "Loading artists…"
      assert tool["_meta"]["openai/toolInvocation/invoked"] == "Artists loaded."
    end

    test "omits _meta field when tool has no meta defined" do
      session_id = initialize_and_get_session_id(@opts_without_meta)

      response = list_tools(session_id, @opts_without_meta)
      body = decode_response(response)

      assert response.status == 200
      tool = Enum.find(body["result"]["tools"], &(&1["name"] == "list_artists"))
      assert tool

      # Verify _meta field is not present
      refute Map.has_key?(tool, "_meta")
    end

    test "includes standard tool fields along with _meta" do
      session_id = initialize_and_get_session_id(@opts_with_meta)

      response = list_tools(session_id, @opts_with_meta)
      body = decode_response(response)

      tool = Enum.find(body["result"]["tools"], &(&1["name"] == "list_artists_with_meta"))

      # Verify all standard fields are present
      assert tool["name"]
      assert tool["description"]
      assert tool["inputSchema"]
      assert tool["_meta"]
    end
  end

  describe "tools/call with _meta" do
    test "includes _meta in response when tool has meta defined" do
      session_id = initialize_and_get_session_id(@opts_with_meta)

      # Create test data
      Music.create_artist_after_action!(%{
        name: "Meta Test Artist",
        bio: "Testing meta field"
      })

      response = call_tool(session_id, "list_artists_with_meta", %{}, @opts_with_meta)
      body = decode_response(response)

      assert response.status == 200
      assert body["jsonrpc"] == "2.0"
      assert body["result"]["isError"] == false

      # Verify _meta field is present in tool call response
      assert body["result"]["_meta"]
      assert body["result"]["_meta"]["openai/outputTemplate"] == "ui://widget/artist-list.html"
      assert body["result"]["_meta"]["openai/toolInvocation/invoking"] == "Loading artists…"
      assert body["result"]["_meta"]["openai/toolInvocation/invoked"] == "Artists loaded."

      # Verify content is still present
      assert body["result"]["content"]
      assert is_list(body["result"]["content"])
    end

    test "omits _meta in response when tool has no meta defined" do
      session_id = initialize_and_get_session_id(@opts_without_meta)

      Music.create_artist_after_action!(%{
        name: "No Meta Artist",
        bio: "Testing without meta"
      })

      response = call_tool(session_id, "list_artists", %{}, @opts_without_meta)
      body = decode_response(response)

      assert response.status == 200
      assert body["result"]["isError"] == false

      # Verify _meta field is not present
      refute Map.has_key?(body["result"], "_meta")

      # Verify content is still present
      assert body["result"]["content"]
    end
  end

  # Helper functions

  defp initialize_and_get_session_id(opts) do
    response =
      conn(:post, "/", %{
        "method" => "initialize",
        "id" => "init_1",
        "params" => %{"client" => %{"name" => "test_client", "version" => "1.0.0"}}
      })
      |> Router.call(opts)

    extract_session_id(response)
  end

  defp list_tools(session_id, opts) do
    conn(:post, "/", %{"method" => "tools/list", "id" => "list_1"})
    |> put_req_header("mcp-session-id", session_id)
    |> Router.call(opts)
  end

  defp call_tool(session_id, tool_name, arguments, opts) do
    conn(:post, "/", %{
      "method" => "tools/call",
      "id" => "call_1",
      "params" => %{"name" => tool_name, "arguments" => arguments}
    })
    |> put_req_header("mcp-session-id", session_id)
    |> Router.call(opts)
  end

  defp extract_session_id(response) do
    List.first(Plug.Conn.get_resp_header(response, "mcp-session-id"))
  end

  defp decode_response(response) do
    Jason.decode!(response.resp_body)
  end
end
