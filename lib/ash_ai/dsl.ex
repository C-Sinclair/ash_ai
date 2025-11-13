# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Dsl do
  @moduledoc """
  Spark DSL extension for AshAi.

  This module contains all the DSL entity and section definitions that define
  how AshAi resources are configured, including tools, vectorization, and MCP resources.
  """

  require Ash.Expr

  @full_text %Spark.Dsl.Entity{
    name: :full_text,
    imports: [Ash.Expr],
    target: AshAi.FullText,
    identifier: :name,
    schema: [
      name: [
        type: :atom,
        default: :full_text_vector,
        doc: "The name of the attribute to store the text vector in"
      ],
      used_attributes: [
        type: {:list, :atom},
        doc: "If set, a vector is only regenerated when these attributes are changed"
      ],
      text: [
        type: {:fun, 1},
        required: true,
        doc:
          "A function or expr that takes a list of records and computes a full text string that will be vectorized. If given an expr, use `atomic_ref` to refer to new values, as this is set as an atomic update."
      ]
    ]
  }

  @vectorize %Spark.Dsl.Section{
    name: :vectorize,
    entities: [
      @full_text
    ],
    schema: [
      attributes: [
        type: :keyword_list,
        doc:
          "A keyword list of attributes to vectorize, and the name of the attribute to store the vector in",
        default: []
      ],
      strategy: [
        type: {:one_of, [:after_action, :manual, :ash_oban, :ash_oban_manual]},
        default: :after_action,
        doc:
          "How to compute the vector. Currently supported strategies are `:after_action`, `:manual`, and `:ash_oban`."
      ],
      define_update_action_for_manual_strategy?: [
        type: :boolean,
        default: true,
        doc:
          "If true, an `ash_ai_update_embeddings` update action will be defined, which will automatically update the embeddings when run."
      ],
      ash_oban_trigger_name: [
        type: :atom,
        default: :ash_ai_update_embeddings,
        doc:
          "The name of the AshOban-trigger that will be run in order to update the record's embeddings. Defaults to `:ash_ai_update_embeddings`."
      ],
      embedding_model: [
        type: {:spark_behaviour, AshAi.EmbeddingModel},
        required: true
      ]
    ]
  }

  @tool %Spark.Dsl.Entity{
    name: :tool,
    describe: """
    Expose an Ash action as a tool that can be called by LLMs.

    Tools allow LLMs to interact with your application by calling specific actions on resources.
    Only public attributes can be used for filtering, sorting, and aggregation, but the `load`
    option allows including private attributes in the response data.
    """,
    target: AshAi.Tools.Tool,
    schema: AshAi.Tools.Tool.schema(),
    args: [:name, :resource, :action]
  }

  @tools %Spark.Dsl.Section{
    name: :tools,
    entities: [
      @tool
    ]
  }

  @mcp_resource %Spark.Dsl.Entity{
    name: :mcp_resource,
    describe: """
    An MCP resource to expose via the Model Context Protocol (MCP).
    MCP Resources are different to Ash Resources. Here they are used to
    respond to LLM models with static or dynamic assets like files, images, or JSON.

    The resource description defaults to the action's description. You can override this
    by providing a `description` option which takes precedence.
    """,
    examples: [
      ~s(mcp_resource :artist_card, "file://info/artist_info.txt", Artist, :artist_info),
      ~s(mcp_resource :artist_card, "file://ui/artist_card.html", Artist, :artist_card, mime_type: "text/html"),
      ~s(mcp_resource :artist_data, "file://data/artist.json", Artist, :to_json, description: "Artist metadata as JSON", mime_type: "application/json")
    ],
    target: AshAi.Mcp.McpResource,
    schema: AshAi.Mcp.McpResource.schema(),
    args: [:name, :uri, :resource, :action]
  }

  @mcp_resources %Spark.Dsl.Section{
    name: :mcp_resources,
    entities: [
      @mcp_resource
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@tools, @vectorize, @mcp_resources],
    imports: [AshAi.Actions],
    transformers: [AshAi.Transformers.Vectorize]
end
