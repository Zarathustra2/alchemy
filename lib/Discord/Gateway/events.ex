defmodule Alchemy.Discord.Events do
  alias Alchemy.{Channel, Emoji, DMChannel, Guild, OverWrite, User,
                 GuildMember, Role, Message, Users.Presence, VoiceState}
  alias Alchemy.Cache.Manager, as: Cache
  alias Alchemy.Cogs.CommandHandler, as: Commands
  import Alchemy.Structs.Utility
  import Alchemy.Cogs.EventHandler, only: [notify: 1]
  @moduledoc false
  # Used to generate events, and notify the main EventManager


  # A direct message was started with the bot
  def handle("CHANNEL_CREATE", %{"is_private" => true} = dm_channel) do
    Cache.add_priv_channel(dm_channel)
    struct = to_struct(dm_channel, DMChannel)
    {:dm_channel_create, [struct]}
  end
  def handle("CHANNEL_CREATE", channel) do
    struct = Channel.from_map(channel)
    {:channel_create, [struct]}
  end

  def handle("CHANNEL_UPDATE", %{"is_private" => true} = dm_channel) do
    Cache.update_priv_channel(dm_channel)
    notify {:dm_channel_update, [to_struct(dm_channel, DMChannel)]}
  end
  def handle("CHANNEL_UPDATE", channel) do
    notify {:channel_update, [Channel.from_map(channel)]}
  end

  def handle("CHANNEL_DELETE", %{"is_private" => true} = dm_channel) do
    Cache.rem_priv_channel(dm_channel["id"])
    notify {:dm_channel_delete, [to_struct(dm_channel, DMChannel)]}
  end

  # The Cache manager is tasked of notifying, if, and only if this guild is new,
  # and not in the unavailable guilds loaded before
  def handle("GUILD_CREATE", guild) do
    Cache.add_guild(guild)
  end

  def handle("GUILD_UPDATE", guild) do
    Cache.update_guild(guild)
    notify {:guild_update, [Guild.from_map(guild)]}
  end

  # The Cache is responsible for notifications in this case
  def handle("GUILD_DELETE", guild) do
    Cache.delete(guild)
  end

  def handle("GUILD_BAN_ADD", %{"guild_id" => id} = user) do
    notify {:guild_ban, [to_struct(user, User), id]}
  end

  def handle("GUILD_BAN_REMOVE", %{"guild_id" => id} = user) do
    notify {:guild_unban, [to_struct(user, User), id]}
  end

  def handle("GUILD_EMOJIS_UPDATE", data) do
    Cache.update_emojis(data)
    notify {:emoji_update, [map_struct(data["emojis"], Emoji), data["guild_id"]]}
  end

  def handle("GUILD_INTEGRATIONS_UPDATE", %{"guild_id" => id}) do
    notify {:integrations_update, [id]}
  end

  def handle("GUILD_MEMBER_ADD", %{"guild_id" => id}) do
    notify {:member_join, [id]}
  end

  def handle("GUILD_MEMBER_REMOVE", %{"guild_id" => id, "user" => user}) do
    Cache.remove_user(id, user)
    notify {:member_leave, [to_struct(user, User), id]}
  end

  def handle("GUILD_MEMBER_UPDATE", %{"guild_id" => id} = data) do
    # This key would get popped implicitly later, but I'd rather do it clearly here
    Cache.update_member(id, Map.delete(data, "guild_id"))
    notify {:member_update, [GuildMember.from_map(data), id]}
  end

  def handle("GUILD_ROLE_CREATE", %{"guild_id" => id, "role" => role}) do
    Cache.add_role(id, role)
    notify {:role_create, [to_struct(role, Role), id]}
  end

  def handle("GUILD_ROLE_DELETE", %{"guild_id" => guild_id, "role_id" => id}) do
    Cache.remove_role(guild_id, id)
    notify {:role_delete, [id, guild_id]}
  end

  def handle("MESSAGE_CREATE", message) do
    struct = Message.from_map(message)
    Commands.dispatch(struct)
    notify {:message_create, [struct]}
  end

  def handle("MESSAGE_UPDATE", message) do
    notify {:message_update, [Message.from_map(message)]}
  end
  def handle("MESSAGE_DELETE", %{"id" => msg_id, "channel_id" => chan_id}) do
    notify {:message_delete, [msg_id, chan_id]}
  end

  def handle("MESSAGE_DELETE_BULK", %{"ids" => ids, "channel_id" => chan_id}) do
    notify {:message_delete_bulk, [ids, chan_id]}
  end

  def handle("PRESENCE_UPDATE", presence) do
    Cache.update_presence(presence)
    notify {:presence_update, [Presence.from_map(presence)]}
  end

  def handle("TYPING_START", data) do
    chan_id = data["channel_id"]
    user_id = data["user_id"]
    timestamp = data["timestamp"]
    notify {:typing_start, [user_id, chan_id, timestamp]}
  end

  def handle("USER_SETTINGS_UPDATE", %{"username" => name, "avatar" => avatar}) do
    notify {:user_settings_update, [name, avatar]}
  end

  def handle("USER_UPDATE", user) do
    notify {:user_update, [to_struct(user, User)]}
  end

  def handle("VOICE_STATE_UPDATE", voice) do
    Cache.update_voice_state(voice)
    notify {:voice_state_update, [to_struct(voice, Voice)]}
  end

  def handle(_, _) do
    nil
  end

end