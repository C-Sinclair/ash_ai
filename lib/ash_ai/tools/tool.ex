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

  @schema [
    name: [type: :atom, required: true],
    resource: [type: {:spark, Ash.Resource}, required: true],
    action: [type: :atom, required: true],
    action_parameters: [
      type: {:list, :atom},
      required: false,
      doc:
        "A list of action specific parameters to allow for the underlying action. Only relevant for reads, and defaults to allowing `[:sort, :offset, :limit, :result_type, :filter]`"
    ],
    load: [
      type: :any,
      default: [],
      doc:
        "A list of relationships and calculations to load on the returned records. Note that loaded fields can include private attributes, which will then be included in the tool's response. However, private attributes cannot be used for filtering, sorting, or aggregation."
    ],
    async: [type: :boolean, default: true],
    description: [
      type: :string,
      doc: "A description for the tool. Defaults to the action's description."
    ],
    identity: [
      type: :atom,
      default: nil,
      doc:
        "The identity to use for update/destroy actions. Defaults to the primary key. Set to `false` to disable entirely."
    ]
  ]

  @doc false
  def schema, do: @schema
end
