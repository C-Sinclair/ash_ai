# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Test.Music do
  @moduledoc false
  use Ash.Domain, otp_app: :ash_ai, extensions: [AshAi.Dsl]

  tools do
    tool :list_artists, AshAi.Test.Music.ArtistAfterAction, :read
  end

  mcp_resources do
    mcp_resource(
      :artist_card,
      "file://ui/artist_card.html",
      AshAi.Test.Music.ArtistUi,
      :artist_card,
      mime_type: "text/html"
    )

    mcp_resource(:artist_json, "file://data/artist.json", AshAi.Test.Music.ArtistUi, :artist_json,
      mime_type: "application/json"
    )

    mcp_resource(
      :artist_with_params,
      "file://ui/custom_card.html",
      AshAi.Test.Music.ArtistUi,
      :artist_card_with_params,
      mime_type: "text/html"
    )

    mcp_resource(
      :failing_resource,
      "file://fail/test",
      AshAi.Test.Music.ArtistUi,
      :failing_action
    )
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
