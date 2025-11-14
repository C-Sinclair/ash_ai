defmodule AshAi.Mcp.McpResource do
  @moduledoc """
  An MCP resource to expose via the Model Context Protocol (MCP).

  MCP resources provide LLMs with access to static or dynamic content like UI components,
  data files, or images. Unlike tools which perform actions, resources return content that
  the LLM can read and reference.

  ## Example

  ```elixir
  defmodule MyApp.Blog do
    use Ash.Domain, extensions: [AshAi.Dsl]

    mcp_resources do
      # Description inherited from :render_card action
      mcp_resource :post_card, "file://ui/post_card.html", Post, :render_card,
        mime_type: "text/html"

      # Custom description overrides action description
      mcp_resource :post_data, "file://data/post.json", Post, :to_json,
        description: "JSON metadata including author, tags, and timestamps",
        mime_type: "application/json"
    end
  end
  ```

  The action is called when an MCP client requests the resource, and its return value
  (which must be a string) is sent to the client with the specified MIME type.

  ## Description Behavior

  Resource descriptions default to the action's description. You can provide a custom
  `description` option in the DSL which takes precedence over the action description.
  This helps LLMs understand when to use each resource.
  """
  @type t :: %__MODULE__{
          name: atom(),
          resource: Ash.Resource.t(),
          action: atom() | Ash.Resource.Actions.Action.t(),
          domain: module() | nil,
          title: String.t(),
          description: String.t(),
          uri: String.t(),
          mime_type: String.t()
        }

  defstruct [
    :name,
    :resource,
    :action,
    :domain,
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
      required: true,
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
      default: "text/plain",
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
