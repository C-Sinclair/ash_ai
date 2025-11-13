defmodule AshAi.Mcp.McpResource do
  @moduledoc "An MCP resource to expose via the Model Context Protocol (MCP)."
  @type t :: %__MODULE__{
          name: atom(),
          resource: Ash.Resource.t(),
          action: atom(),
          title: String.t(),
          description: String.t(),
          uri: String.t(),
          mime_type: String.t()
        }

  defstruct [
    :name,
    :resource,
    :action,
    :title,
    :description,
    :uri,
    :mime_type,
    __spark_metadata__: nil
  ]

  @schema [
    name: [type: :atom, required: true],
    title: [
      type: :string,
      doc: "A short, human-readable title for the resource."
    ],
    description: [
      type: :string,
      doc:
        "A description of the resource. This is important for LLM to determine what the resource is and when to call it.
        Defaults to the Action's description if not provided."
    ],
    uri: [
      type: :string,
      required: true,
      doc: "The URI where the resource can be accessed."
    ],
    mime_type: [
      type: :string,
      default: "plain/text",
      doc: "The MIME type of the resource, e.g. 'application/json', 'image/png', etc."
    ],
    resource: [type: {:spark, Ash.Resource}, required: true],
    action: [type: :atom, required: true],
    action_parameters: [
      type: {:list, :atom},
      required: false,
      doc:
        "A list of action specific parameters to allow for the underlying action. Only relevant for reads, and defaults to allowing `[:sort, :offset, :limit, :result_type, :filter]`"
    ]
  ]

  @doc false
  def schema, do: @schema
end
