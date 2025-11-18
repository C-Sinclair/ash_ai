# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Tools.Tool do
  @moduledoc "An action exposed to LLM agents"
  defstruct [
    :name,
    :resource,
    :action,
    :load,
    :async,
    :domain,
    :identity,
    :description,
    :action_parameters,
    __spark_metadata__: nil
  ]
end
