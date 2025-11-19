# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.ExposedToolsTest do
  @moduledoc """
  Tests for AshAi.exposed_tools/1 filtering logic.

  This tests the core filtering functionality separate from the LLM integration.
  """
  use AshAi.RepoCase, async: true

  alias AshAi.Test.Music

  @opts [otp_app: :ash_ai]

  describe "tools filtering" do
    test "tools: nil returns all tools (default)" do
      tools = AshAi.exposed_tools(@opts)
      assert length(tools) == 5
    end

    test "tools: specific list filters to only those tools" do
      opts = Keyword.put(@opts, :tools, [:list_artists, :create_artist_after])
      tools = AshAi.exposed_tools(opts)

      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :create_artist_after in tool_names
      refute :update_artist_after in tool_names
    end

    test "tools: single tool in list" do
      opts = Keyword.put(@opts, :tools, [:create_artist_manual])
      tools = AshAi.exposed_tools(opts)

      assert length(tools) == 1
      assert hd(tools).name == :create_artist_manual
    end

    test "tools: empty list returns no tools" do
      opts = Keyword.put(@opts, :tools, [])
      tools = AshAi.exposed_tools(opts)

      assert Enum.empty?(tools)
    end
  end

  describe "actions filtering" do
    test "actions: specific list filters resource/action pairs" do
      opts = Keyword.put(@opts, :actions, [{Music.ArtistAfterAction, [:read, :create]}])
      tools = AshAi.exposed_tools(opts)

      # Should return only tools using read and create actions on ArtistAfterAction
      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :create_artist_after in tool_names
      refute :update_artist_after in tool_names
    end

    test "actions: wildcard returns all actions for resource" do
      opts = Keyword.put(@opts, :actions, [{Music.ArtistAfterAction, :*}])
      tools = AshAi.exposed_tools(opts)

      # Should return all 3 tools for ArtistAfterAction
      assert length(tools) == 3
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :create_artist_after in tool_names
      assert :update_artist_after in tool_names
      refute :create_artist_manual in tool_names
    end

    test "actions: multiple resources" do
      opts =
        Keyword.put(@opts, :actions, [
          {Music.ArtistAfterAction, [:read]},
          {Music.ArtistManual, [:create]}
        ])

      tools = AshAi.exposed_tools(opts)

      # Should return tools from both resources with specified actions
      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :create_artist_manual in tool_names
    end

    test "actions: raises when action not exposed as tool" do
      assert_raise RuntimeError, "Cannot use an action that is not exposed as a tool", fn ->
        AshAi.exposed_tools(actions: [{Music.ArtistAfterAction, [:destroy]}])
      end
    end
  end

  describe "exclude_actions filtering" do
    test "exclude_actions: removes specific resource/action pairs" do
      opts = Keyword.put(@opts, :exclude_actions, [{Music.ArtistAfterAction, :create}])
      tools = AshAi.exposed_tools(opts)

      # Should return 4 tools (all 5 except create_artist_after)
      assert length(tools) == 4
      tool_names = Enum.map(tools, & &1.name)
      refute :create_artist_after in tool_names
      assert :list_artists in tool_names
      assert :update_artist_after in tool_names
    end

    test "exclude_actions: multiple exclusions" do
      opts =
        Keyword.put(@opts, :exclude_actions, [
          {Music.ArtistAfterAction, :create},
          {Music.ArtistManual, :update}
        ])

      tools = AshAi.exposed_tools(opts)

      # Should return 3 tools
      assert length(tools) == 3
      tool_names = Enum.map(tools, & &1.name)
      refute :create_artist_after in tool_names
      refute :update_artist_manual in tool_names
      assert :list_artists in tool_names
      assert :create_artist_manual in tool_names
    end
  end

  describe "combined filtering" do
    test "tools + actions: both filters applied" do
      # Filter to specific tools AND specific actions
      opts =
        @opts
        |> Keyword.put(:tools, [:list_artists, :create_artist_after, :create_artist_manual])
        |> Keyword.put(:actions, [{Music.ArtistAfterAction, [:read, :create]}])

      tools = AshAi.exposed_tools(opts)

      # tools filter allows 3, but actions filter only allows ArtistAfterAction read/create
      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :create_artist_after in tool_names
      refute :create_artist_manual in tool_names
    end

    test "tools + exclude_actions: exclusion applied after tools filter" do
      opts =
        @opts
        |> Keyword.put(:tools, [:list_artists, :create_artist_after, :update_artist_after])
        |> Keyword.put(:exclude_actions, [{Music.ArtistAfterAction, :create}])

      tools = AshAi.exposed_tools(opts)

      # Should return 2 tools (list_artists and update_artist_after)
      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :update_artist_after in tool_names
      refute :create_artist_after in tool_names
    end

    test "all filters work together: actions + tools + exclude_actions" do
      opts =
        @opts
        |> Keyword.put(:actions, [{Music.ArtistAfterAction, :*}])
        |> Keyword.put(:tools, [:list_artists, :create_artist_after, :update_artist_after])
        |> Keyword.put(:exclude_actions, [{Music.ArtistAfterAction, :create}])

      tools = AshAi.exposed_tools(opts)

      # actions allows all ArtistAfterAction, tools filter to 3, exclude_actions removes create
      assert length(tools) == 2
      tool_names = Enum.map(tools, & &1.name)
      assert :list_artists in tool_names
      assert :update_artist_after in tool_names
      refute :create_artist_after in tool_names
    end
  end

  describe "edge cases" do
    test "raises when no otp_app and no actions" do
      assert_raise RuntimeError, "Must specify `otp_app` if you do not specify `actions`", fn ->
        AshAi.exposed_tools([])
      end
    end

    test "empty result when actions filter matches nothing" do
      opts = Keyword.put(@opts, :actions, [{Music.ArtistAfterAction, [:destroy]}])

      assert_raise RuntimeError, "Cannot use an action that is not exposed as a tool", fn ->
        AshAi.exposed_tools(opts)
      end
    end

    test "empty result when tools filter matches nothing" do
      opts = Keyword.put(@opts, :tools, [:nonexistent_tool])
      tools = AshAi.exposed_tools(opts)

      assert Enum.empty?(tools)
    end

    test "returns enriched tools with domain and action metadata" do
      tools = AshAi.exposed_tools(@opts)

      for tool <- tools do
        assert tool.domain
        assert tool.action
        assert is_struct(tool.action)
        assert tool.resource
      end
    end

    test "tools are deduplicated" do
      # Even if multiple domains expose the same tool, it should appear once
      tools = AshAi.exposed_tools(@opts)

      tool_names = Enum.map(tools, & &1.name)
      assert length(tool_names) == length(Enum.uniq(tool_names))
    end
  end
end
