# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.FullText do
  @moduledoc "A section that defines how complex vectorized columns are defined"
  defstruct [
    :used_attributes,
    :text,
    :__identifier__,
    name: :full_text_vector,
    __spark_metadata__: nil
  ]
end
