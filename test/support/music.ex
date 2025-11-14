# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Test.Music do
  @moduledoc false
  use Ash.Domain, otp_app: :ash_ai, extensions: [AshAi]

  tools do
    tool :list_artists, AshAi.Test.Music.ArtistAfterAction, :read

    tool :list_artists_with_meta, AshAi.Test.Music.ArtistAfterAction, :read,
      description: "List artists with OpenAI metadata",
      meta: %{
        "openai/outputTemplate" => "ui://widget/artist-list.html",
        "openai/toolInvocation/invoking" => "Loading artists…",
        "openai/toolInvocation/invoked" => "Artists loaded."
      }
  end

  mcp_resources do
    mcp_resource :artist_card,
                 "file://ui/artist_card.html",
                 AshAi.Test.Music.ArtistUi,
                 :artist_card do
      title "Artist Card"
      mime_type "text/html"
    end

    mcp_resource :artist_json,
                 "file://data/artist.json",
                 AshAi.Test.Music.ArtistUi,
                 :artist_json do
      title "Artist JSON"
      mime_type "application/json"
    end

    mcp_resource :artist_with_params,
                 "file://ui/custom_card.html",
                 AshAi.Test.Music.ArtistUi,
                 :artist_card_with_params do
      title "Artist Card With Params"
      mime_type "text/html"
    end

    mcp_resource :failing_resource,
                 "file://fail/test",
                 AshAi.Test.Music.ArtistUi,
                 :failing_action do
      title "Failing Resource"
    end

    mcp_resource :artist_card_custom,
                 "file://ui/custom_description.html",
                 AshAi.Test.Music.ArtistUi,
                 :artist_card do
      title "Artist Card Custom"
      description "Custom description from DSL"
      mime_type "text/html"
    end
  end

  resources do
    resource AshAi.Test.Music.ArtistAfterAction do
      define :create_artist_after_action, action: :create
      define :update_artist_after_action, action: :update
    end

    resource AshAi.Test.Music.ArtistManual do
      define :create_artist_manual, action: :create
      define :update_artist_manual, action: :update
      define :update_embeddings_artist_manual, action: :ash_ai_update_embeddings
    end

    resource AshAi.Test.Music.ArtistOban do
      define :create_artist_oban, action: :create
      define :update_artist_oban, action: :update
    end

    resource AshAi.Test.Music.ArtistUi
  end
end
