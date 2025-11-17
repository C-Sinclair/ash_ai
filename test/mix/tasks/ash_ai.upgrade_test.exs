# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AshAi.UpgradeTest do
  use ExUnit.Case, async: false

  test "migrates single AshAi extension to AshAi.Dsl" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshAi]

      resources do
        resource MyApp.User
      end
    end
    """

    expected = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshAi.Dsl]

      resources do
        resource MyApp.User
      end
    end
    """

    assert_upgrade(input, expected)
  end

  test "migrates AshAi in list with other extensions" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain,
        extensions: [AshAi, AshJsonApi, AshGraphql]

      resources do
        resource MyApp.User
      end
    end
    """

    expected = """
    defmodule MyApp.Accounts do
      use Ash.Domain,
        extensions: [AshAi.Dsl, AshJsonApi, AshGraphql]

      resources do
        resource MyApp.User
      end
    end
    """

    assert_upgrade(input, expected)
  end

  test "migrates multiple domains in same file" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshAi]
    end

    defmodule MyApp.Blog do
      use Ash.Domain, extensions: [AshAi, AshJsonApi]
    end
    """

    expected = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshAi.Dsl]
    end

    defmodule MyApp.Blog do
      use Ash.Domain, extensions: [AshAi.Dsl, AshJsonApi]
    end
    """

    assert_upgrade(input, expected)
  end

  test "does not modify domains without AshAi extension" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshJsonApi]

      resources do
        resource MyApp.User
      end
    end
    """

    assert_upgrade(input, input)
  end

  test "does not modify already-upgraded domains using AshAi.Dsl" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: [AshAi.Dsl]

      resources do
        resource MyApp.User
      end
    end
    """

    assert_upgrade(input, input)
  end

  test "handles domain with no extensions keyword" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain

      resources do
        resource MyApp.User
      end
    end
    """

    assert_upgrade(input, input)
  end

  test "handles compact syntax with single extension" do
    input = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: AshAi
    end
    """

    expected = """
    defmodule MyApp.Accounts do
      use Ash.Domain, extensions: AshAi.Dsl
    end
    """

    assert_upgrade(input, expected)
  end

  test "preserves formatting and comments" do
    input = """
    defmodule MyApp.Accounts do
      # This is our main accounts domain
      use Ash.Domain,
        # We use AshAi for LLM integration
        extensions: [AshAi]

      resources do
        resource MyApp.User
      end
    end
    """

    result = run_upgrade(input)

    assert result =~ "# This is our main accounts domain"
    assert result =~ "# We use AshAi for LLM integration"
    assert result =~ "extensions: [AshAi.Dsl]"
    refute result =~ "extensions: [AshAi]"
  end

  test "handles mix of AshAi and AshAi.Dsl modules (idempotent)" do
    input = """
    defmodule MyApp.Old do
      use Ash.Domain, extensions: [AshAi]
    end

    defmodule MyApp.New do
      use Ash.Domain, extensions: [AshAi.Dsl]
    end
    """

    expected = """
    defmodule MyApp.Old do
      use Ash.Domain, extensions: [AshAi.Dsl]
    end

    defmodule MyApp.New do
      use Ash.Domain, extensions: [AshAi.Dsl]
    end
    """

    assert_upgrade(input, expected)
  end

  test "does not affect non-Domain modules" do
    input = """
    defmodule MyApp.User do
      use Ash.Resource, extensions: [AshAi]

      attributes do
        uuid_primary_key :id
      end
    end
    """

    assert_upgrade(input, input)
  end

  defp assert_upgrade(input, expected) do
    result = run_upgrade(input)

    assert String.trim(result) == String.trim(expected),
           """
           Upgrade did not produce expected output.

           Expected:
           #{expected}

           Got:
           #{result}
           """
  end

  defp run_upgrade(input) do
    igniter =
      Igniter.new()
      |> Igniter.create_new_file("lib/test.ex", input)

    igniter = Mix.Tasks.AshAi.Upgrade.migrate_extension_name(igniter, [])

    # Get the modified source from the rewrite structure
    source = Rewrite.source!(igniter.rewrite, "lib/test.ex")
    Rewrite.Source.get(source, :content)
  end
end
