# SPDX-FileCopyrightText: 2024 ash_ai contributors <https://github.com/ash-project/ash_ai/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAi.Test.Music do
  @moduledoc false
  use Ash.Domain, otp_app: :ash_ai, extensions: [AshAi]

  tools do
    tool :list_artists, AshAi.Test.Music.ArtistAfterAction, :read
    tool :create_artist_after, AshAi.Test.Music.ArtistAfterAction, :create
    tool :update_artist_after, AshAi.Test.Music.ArtistAfterAction, :update
    tool :create_artist_manual, AshAi.Test.Music.ArtistManual, :create
    tool :update_artist_manual, AshAi.Test.Music.ArtistManual, :update
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
  end
end
