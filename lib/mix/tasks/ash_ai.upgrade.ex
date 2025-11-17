# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshAi.Upgrade do
    @moduledoc """
    Upgrades AshAi between versions, running automatic code transformations.

    ## Example

        mix ash_ai.upgrade 0.3.0 0.4.0

    This will run all upgrade tasks between the specified versions.
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :ash,
        positional: [:from, :to],
        schema: [],
        example: "mix ash_ai.upgrade 0.3.0 0.4.0"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      positional = igniter.args.positional
      options = igniter.args.options

      upgrades = %{
        "0.4.0" => [&migrate_extension_name/2]
      }

      Igniter.Upgrades.run(igniter, positional.from, positional.to, upgrades,
        custom_opts: options
      )
    end

    @doc """
    Migrates `extensions: [AshAi]` to `extensions: [AshAi.Dsl]` in all Ash.Domain modules.

    This upgrade is necessary because the extension was moved to a separate DSL module
    for better organization and to follow Ash Framework conventions.
    """
    def migrate_extension_name(igniter, _opts) do
      igniter
      |> find_modules_with_old_extension()
      |> case do
        {igniter, []} ->
          igniter

        {igniter, modules} ->
          modules
          |> Enum.reduce(igniter, &update_module_extension/2)
      end
    end

    defp find_modules_with_old_extension(igniter) do
      Igniter.Project.Module.find_all_matching_modules(igniter, fn _module, zipper ->
        with {:ok, zipper} <- Igniter.Code.Module.move_to_use(zipper, Ash.Domain),
             {:ok, zipper} <- Igniter.Code.Function.move_to_nth_argument(zipper, 1),
             {:ok, zipper} <- Igniter.Code.Keyword.get_key(zipper, :extensions) do
          has_ash_ai_extension?(zipper)
        else
          _ -> false
        end
      end)
    end

    defp has_ash_ai_extension?(zipper) do
      if Igniter.Code.List.list?(zipper) do
        match?(
          {:ok, _},
          Igniter.Code.List.move_to_list_item(
            zipper,
            &Igniter.Code.Common.nodes_equal?(&1, AshAi)
          )
        )
      else
        Igniter.Code.Common.nodes_equal?(zipper, AshAi)
      end
    end

    defp update_module_extension(module, igniter) do
      Igniter.Project.Module.find_and_update_module!(igniter, module, fn zipper ->
        with {:ok, zipper} <- Igniter.Code.Module.move_to_use(zipper, Ash.Domain),
             {:ok, zipper} <- Igniter.Code.Function.move_to_nth_argument(zipper, 1),
             {:ok, zipper} <- Igniter.Code.Keyword.get_key(zipper, :extensions) do
          replace_ash_ai_with_dsl(zipper)
        else
          :error -> {:ok, zipper}
        end
      end)
    end

    defp replace_ash_ai_with_dsl(zipper) do
      if Igniter.Code.List.list?(zipper) do
        Igniter.Code.List.replace_in_list(
          zipper,
          &Igniter.Code.Common.nodes_equal?(&1, AshAi),
          AshAi.Dsl
        )
      else
        if Igniter.Code.Common.nodes_equal?(zipper, AshAi) do
          {:ok, Sourceror.Zipper.replace(zipper, quote(do: AshAi.Dsl))}
        else
          {:ok, zipper}
        end
      end
    end
  end
end
