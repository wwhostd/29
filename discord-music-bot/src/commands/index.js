import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  ModalBuilder,
  PermissionFlagsBits,
  SlashCommandBuilder,
  StringSelectMenuBuilder,
  TextInputBuilder,
  TextInputStyle
} from 'discord.js';
import { config } from '../config.js';
import { errorEmbed, infoEmbed, panelEmbed, successEmbed } from '../utils/embeds.js';
import { PlaylistStore } from '../utils/playlists.js';

const playlistStore = new PlaylistStore();

export const PANEL_IDS = {
  addSong: 'music:panel:add-song',
  join: 'music:panel:join',
  leave: 'music:panel:leave',
  pause: 'music:panel:pause',
  resume: 'music:panel:resume',
  skip: 'music:panel:skip',
  stop: 'music:panel:stop',
  volUp: 'music:panel:vol-up',
  volDown: 'music:panel:vol-down',
  playlistAction: 'music:panel:playlist-action',
  playlistCreateModal: 'music:panel:playlist-create-modal',
  playlistCreateName: 'music:panel:playlist-create-name',
  playlistDeleteModal: 'music:panel:playlist-delete-modal',
  playlistDeleteName: 'music:panel:playlist-delete-name',
  playlistAddModal: 'music:panel:playlist-add-modal',
  playlistAddName: 'music:panel:playlist-add-name',
  playlistAddQuery: 'music:panel:playlist-add-query',
  playlistRemoveModal: 'music:panel:playlist-remove-modal',
  playlistRemoveName: 'music:panel:playlist-remove-name',
  playlistRemoveIndex: 'music:panel:playlist-remove-index',
  playlistPlayModal: 'music:panel:playlist-play-modal',
  playlistPlayName: 'music:panel:playlist-play-name',
  addModal: 'music:panel:add-modal',
  addModalQuery: 'music:panel:add-modal-query'
};

const hasPlaylistRole = (member) => {
  if (!config.playlistManagerRoleId) return true;
  return member.roles.cache.has(config.playlistManagerRoleId);
};

const ensureVoice = (interaction) => {
  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) {
    return {
      ok: false,
      reply: {
        embeds: [errorEmbed('Voice Channel Required', 'لازم تدخل روم صوتي عشان تستخدم الموسيقى.')],
        ephemeral: true
      }
    };
  }

  return { ok: true, voiceChannel };
};

const enforceTrackOwner = (interaction, player) => {
  if (!player.current || player.canControl(interaction.user.id)) return { ok: true };
  return {
    ok: false,
    reply: {
      embeds: [errorEmbed('Control Locked', 'فقط الشخص اللي شغّل الأغنية الحالية يقدر يوقف/يتخطى.')],
      ephemeral: true
    }
  };
};

const queueResponse = (player) => {
  const now = player.current;
  const queued = player.getQueuePreview();

  if (!now && queued.length === 0) {
    return { embeds: [infoEmbed('Queue Empty', 'الطابور فاضي حالياً.')], ephemeral: true };
  }

  const list = queued.map((track, idx) => `${idx + 1}. [${track.title}](${track.url}) - \`${track.duration}\``).join('\n');
  const description = `${now ? `**Now:** [${now.title}](${now.url}) - \`${now.duration}\`\n\n` : ''}${list || 'لا توجد عناصر إضافية.'}`;
  return { embeds: [infoEmbed('Queue', description)] };
};

export const buildPanelComponents = () => {
  const row1 = new ActionRowBuilder().addComponents(
    new ButtonBuilder().setCustomId(PANEL_IDS.addSong).setLabel('Add Song').setStyle(ButtonStyle.Success).setEmoji('➕'),
    new ButtonBuilder().setCustomId(PANEL_IDS.join).setLabel('Join').setStyle(ButtonStyle.Primary),
    new ButtonBuilder().setCustomId(PANEL_IDS.leave).setLabel('Leave').setStyle(ButtonStyle.Secondary),
    new ButtonBuilder().setCustomId(PANEL_IDS.pause).setLabel('Pause').setStyle(ButtonStyle.Secondary),
    new ButtonBuilder().setCustomId(PANEL_IDS.resume).setLabel('Resume').setStyle(ButtonStyle.Secondary)
  );

  const row2 = new ActionRowBuilder().addComponents(
    new ButtonBuilder().setCustomId(PANEL_IDS.skip).setLabel('Next').setStyle(ButtonStyle.Primary),
    new ButtonBuilder().setCustomId(PANEL_IDS.stop).setLabel('Stop').setStyle(ButtonStyle.Danger),
    new ButtonBuilder().setCustomId(PANEL_IDS.volUp).setLabel('Vol +').setStyle(ButtonStyle.Primary),
    new ButtonBuilder().setCustomId(PANEL_IDS.volDown).setLabel('Vol -').setStyle(ButtonStyle.Primary)
  );

  const row3 = new ActionRowBuilder().addComponents(
    new StringSelectMenuBuilder()
      .setCustomId(PANEL_IDS.playlistAction)
      .setPlaceholder('Playlist Manager')
      .addOptions(
        { label: 'Create Playlist', value: 'create' },
        { label: 'Delete Playlist', value: 'delete' },
        { label: 'Add Song to Playlist', value: 'add' },
        { label: 'Remove Song from Playlist', value: 'remove' },
        { label: 'List Playlists', value: 'list' },
        { label: 'Play Playlist (Ordered)', value: 'play_ordered' },
        { label: 'Play Playlist (Shuffle)', value: 'play_shuffle' }
      )
  );

  return [row1, row2, row3];
};

const enqueueTrack = async (interaction, player, query) => {
  const gate = ensureVoice(interaction);
  if (!gate.ok) return gate.reply;

  await player.connect(gate.voiceChannel);
  const track = await player.enqueue(query, interaction.user.tag, interaction.user.id);
  return {
    embeds: [
      successEmbed('Added to Queue', `**[${track.title}](${track.url})**\nالمدة: \`${track.duration}\`\nالطلب: **${track.requestedBy}**`)
        .setThumbnail(track.thumbnail ?? null)
    ]
  };
};

const createModal = (id, title, fields) => {
  const modal = new ModalBuilder().setCustomId(id).setTitle(title);
  for (const field of fields) {
    modal.addComponents(
      new ActionRowBuilder().addComponents(
        new TextInputBuilder()
          .setCustomId(field.id)
          .setLabel(field.label)
          .setPlaceholder(field.placeholder ?? '')
          .setStyle(TextInputStyle.Short)
          .setRequired(field.required ?? true)
          .setMaxLength(field.maxLength ?? 200)
      )
    );
  }
  return modal;
};

const ensurePanelChannel = (interaction) => {
  if (!config.panelChannelId) return { ok: true };
  if (interaction.channelId === config.panelChannelId) return { ok: true };
  return {
    ok: false,
    reply: {
      embeds: [errorEmbed('Panel Channel Only', 'استخدم البانل في الروم المخصص فقط.')],
      ephemeral: true
    }
  };
};

export const handlePanelButton = async (interaction, musicManager) => {
  if (!Object.values(PANEL_IDS).includes(interaction.customId)) return false;
  const channelGate = ensurePanelChannel(interaction);
  if (!channelGate.ok) {
    await interaction.reply(channelGate.reply);
    return true;
  }

  const player = musicManager.getPlayer(interaction.guildId);

  if (interaction.customId === PANEL_IDS.addSong) {
    await interaction.showModal(createModal(PANEL_IDS.addModal, 'Add Song', [{ id: PANEL_IDS.addModalQuery, label: 'رابط أو اسم الأغنية' }]));
    return true;
  }

  if (interaction.customId === PANEL_IDS.join) {
    const gate = ensureVoice(interaction);
    if (!gate.ok) {
      await interaction.reply(gate.reply);
      return true;
    }
    await player.connect(gate.voiceChannel);
    await interaction.reply({ embeds: [successEmbed('Joined', 'دخلت الروم الصوتي بنجاح.')] });
    return true;
  }

  if (interaction.customId === PANEL_IDS.leave) {
    musicManager.destroyPlayer(interaction.guildId);
    await interaction.reply({ embeds: [infoEmbed('Disconnected', 'تم الخروج من الروم الصوتي.')] });
    return true;
  }

  if (interaction.customId === PANEL_IDS.pause) {
    const lock = enforceTrackOwner(interaction, player);
    if (!lock.ok) {
      await interaction.reply(lock.reply);
      return true;
    }
    const ok = player.pause();
    await interaction.reply({ embeds: [ok ? infoEmbed('Paused', 'تم الإيقاف المؤقت.') : errorEmbed('Pause Failed', 'لا يوجد تشغيل.')], ephemeral: !ok });
    return true;
  }

  if (interaction.customId === PANEL_IDS.resume) {
    const ok = player.resume();
    await interaction.reply({ embeds: [ok ? successEmbed('Resumed', 'تم الاستكمال.') : errorEmbed('Resume Failed', 'لا يوجد إيقاف مؤقت.')], ephemeral: !ok });
    return true;
  }

  if (interaction.customId === PANEL_IDS.skip) {
    const lock = enforceTrackOwner(interaction, player);
    if (!lock.ok) {
      await interaction.reply(lock.reply);
      return true;
    }
    const ok = player.skip();
    await interaction.reply({ embeds: [ok ? infoEmbed('Skipped', 'تم تشغيل الأغنية التالية.') : errorEmbed('Skip Failed', 'لا يوجد تشغيل.')], ephemeral: !ok });
    return true;
  }

  if (interaction.customId === PANEL_IDS.stop) {
    const lock = enforceTrackOwner(interaction, player);
    if (!lock.ok) {
      await interaction.reply(lock.reply);
      return true;
    }
    player.stop();
    await interaction.reply({ embeds: [infoEmbed('Stopped', 'تم إيقاف الموسيقى ومسح الطابور.')] });
    return true;
  }

  if (interaction.customId === PANEL_IDS.volUp) {
    const v = player.setVolume(player.volume + 0.1);
    await interaction.reply({ embeds: [successEmbed('Volume', `تم رفع الصوت إلى **${Math.round(v * 100)}%**`)] });
    return true;
  }

  if (interaction.customId === PANEL_IDS.volDown) {
    const v = player.setVolume(player.volume - 0.1);
    await interaction.reply({ embeds: [successEmbed('Volume', `تم خفض الصوت إلى **${Math.round(v * 100)}%**`)] });
    return true;
  }

  return false;
};

export const handlePanelSelectMenu = async (interaction, musicManager) => {
  if (interaction.customId !== PANEL_IDS.playlistAction) return false;

  const channelGate = ensurePanelChannel(interaction);
  if (!channelGate.ok) {
    await interaction.reply(channelGate.reply);
    return true;
  }

  const action = interaction.values[0];

  if (action === 'list') {
    const playlists = playlistStore.listPlaylists(interaction.guildId);
    const desc = playlists.length
      ? playlists.map((p) => `• **${p.name}** (${p.tracks.length} tracks)`).join('\n')
      : 'ما فيه بلاي ليستات حالياً.';

    await interaction.reply({ embeds: [infoEmbed('Playlists', desc)], ephemeral: true });
    return true;
  }

  if (action.startsWith('play_')) {
    const mode = action === 'play_shuffle' ? 'shuffle' : 'ordered';
    await interaction.showModal(createModal(PANEL_IDS.playlistPlayModal, 'Play Playlist', [{ id: PANEL_IDS.playlistPlayName, label: 'اسم القائمة' }]));
    interaction.client.__playlistPlayMode = interaction.client.__playlistPlayMode ?? {};
    interaction.client.__playlistPlayMode[interaction.user.id] = mode;
    return true;
  }

  if (!hasPlaylistRole(interaction.member)) {
    await interaction.reply({
      embeds: [errorEmbed('Permission Denied', 'ما عندك الرول المطلوب لإدارة البلاي ليست.')],
      ephemeral: true
    });
    return true;
  }

  if (action === 'create') {
    await interaction.showModal(createModal(PANEL_IDS.playlistCreateModal, 'Create Playlist', [{ id: PANEL_IDS.playlistCreateName, label: 'اسم القائمة' }]));
    return true;
  }

  if (action === 'delete') {
    await interaction.showModal(createModal(PANEL_IDS.playlistDeleteModal, 'Delete Playlist', [{ id: PANEL_IDS.playlistDeleteName, label: 'اسم القائمة' }]));
    return true;
  }

  if (action === 'add') {
    await interaction.showModal(
      createModal(PANEL_IDS.playlistAddModal, 'Add Song to Playlist', [
        { id: PANEL_IDS.playlistAddName, label: 'اسم القائمة' },
        { id: PANEL_IDS.playlistAddQuery, label: 'رابط/اسم الأغنية' }
      ])
    );
    return true;
  }

  if (action === 'remove') {
    await interaction.showModal(
      createModal(PANEL_IDS.playlistRemoveModal, 'Remove Song from Playlist', [
        { id: PANEL_IDS.playlistRemoveName, label: 'اسم القائمة' },
        { id: PANEL_IDS.playlistRemoveIndex, label: 'رقم الأغنية (1,2,3...)', maxLength: 6 }
      ])
    );
    return true;
  }

  await interaction.reply({ embeds: [errorEmbed('Unknown Action', 'إجراء غير مدعوم.')], ephemeral: true });
  return true;
};

export const handlePanelModal = async (interaction, musicManager) => {
  const player = musicManager.getPlayer(interaction.guildId);

  if (interaction.customId === PANEL_IDS.addModal) {
    const query = interaction.fields.getTextInputValue(PANEL_IDS.addModalQuery);
    try {
      const payload = await enqueueTrack(interaction, player, query);
      await interaction.reply(payload);
    } catch {
      await interaction.reply({ embeds: [errorEmbed('Playback Error', 'تعذر تشغيل الأغنية المطلوبة.')], ephemeral: true });
    }
    return true;
  }

  if (interaction.customId === PANEL_IDS.playlistCreateModal) {
    try {
      const name = interaction.fields.getTextInputValue(PANEL_IDS.playlistCreateName);
      playlistStore.createPlaylist(interaction.guildId, name, interaction.user.id);
      await interaction.reply({ embeds: [successEmbed('Playlist Created', `تم إنشاء قائمة **${name}**`)], ephemeral: true });
    } catch (error) {
      await interaction.reply({ embeds: [errorEmbed('Create Failed', error.message)], ephemeral: true });
    }
    return true;
  }

  if (interaction.customId === PANEL_IDS.playlistDeleteModal) {
    try {
      const name = interaction.fields.getTextInputValue(PANEL_IDS.playlistDeleteName);
      playlistStore.deletePlaylist(interaction.guildId, name);
      await interaction.reply({ embeds: [successEmbed('Playlist Deleted', `تم حذف قائمة **${name}**`)], ephemeral: true });
    } catch (error) {
      await interaction.reply({ embeds: [errorEmbed('Delete Failed', error.message)], ephemeral: true });
    }
    return true;
  }

  if (interaction.customId === PANEL_IDS.playlistAddModal) {
    try {
      const name = interaction.fields.getTextInputValue(PANEL_IDS.playlistAddName);
      const query = interaction.fields.getTextInputValue(PANEL_IDS.playlistAddQuery);
      const track = await player.resolveTrack(query, interaction.user.tag, interaction.user.id);
      const playlist = playlistStore.addTrack(interaction.guildId, name, track);
      await interaction.reply({
        embeds: [successEmbed('Playlist Updated', `تمت إضافة **${track.title}** إلى **${playlist.name}**`)],
        ephemeral: true
      });
    } catch (error) {
      await interaction.reply({ embeds: [errorEmbed('Add Failed', error.message)], ephemeral: true });
    }
    return true;
  }

  if (interaction.customId === PANEL_IDS.playlistRemoveModal) {
    try {
      const name = interaction.fields.getTextInputValue(PANEL_IDS.playlistRemoveName);
      const index = Number(interaction.fields.getTextInputValue(PANEL_IDS.playlistRemoveIndex)) - 1;
      const removed = playlistStore.removeTrack(interaction.guildId, name, index);
      await interaction.reply({ embeds: [successEmbed('Playlist Updated', `تم حذف **${removed.title}** من **${name}**`)], ephemeral: true });
    } catch (error) {
      await interaction.reply({ embeds: [errorEmbed('Remove Failed', error.message)], ephemeral: true });
    }
    return true;
  }

  if (interaction.customId === PANEL_IDS.playlistPlayModal) {
    try {
      const gate = ensureVoice(interaction);
      if (!gate.ok) {
        await interaction.reply(gate.reply);
        return true;
      }

      const name = interaction.fields.getTextInputValue(PANEL_IDS.playlistPlayName);
      const playlist = playlistStore.getPlaylist(interaction.guildId, name);
      if (!playlist) throw new Error('Playlist not found.');
      if (!playlist.tracks.length) throw new Error('Playlist is empty.');

      const mode = interaction.client.__playlistPlayMode?.[interaction.user.id] ?? 'ordered';
      await player.connect(gate.voiceChannel);
      await player.enqueuePlaylist(playlist.tracks, mode, interaction.user.tag, interaction.user.id);

      await interaction.reply({
        embeds: [successEmbed('Playlist Queued', `تمت إضافة قائمة **${playlist.name}** (${playlist.tracks.length} tracks) بنمط **${mode}**`)]
      });
    } catch (error) {
      await interaction.reply({ embeds: [errorEmbed('Play Playlist Failed', error.message)], ephemeral: true });
    }
    return true;
  }

  return false;
};

export const slashCommands = [
  new SlashCommandBuilder().setName('setup-panel').setDescription('إرسال لوحة التحكم في الروم المحدد').setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),
  new SlashCommandBuilder().setName('queue').setDescription('عرض الطابور الحالي'),
  new SlashCommandBuilder().setName('nowplaying').setDescription('عرض الأغنية الحالية'),
  new SlashCommandBuilder().setName('disconnect').setDescription('إخراج البوت من الروم الصوتي').setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
].map((command) => command.toJSON());

export const handleCommand = async (interaction, musicManager) => {
  const player = musicManager.getPlayer(interaction.guildId);

  if (interaction.commandName === 'setup-panel') {
    if (!config.panelChannelId) {
      return interaction.reply({ embeds: [errorEmbed('Missing Config', 'حدد MUSIC_PANEL_CHANNEL_ID في .env')], ephemeral: true });
    }

    const channel = await interaction.guild.channels.fetch(config.panelChannelId).catch(() => null);
    if (!channel?.isTextBased()) {
      return interaction.reply({ embeds: [errorEmbed('Invalid Channel', 'تأكد من روم البانل وصلاحيات البوت.')], ephemeral: true });
    }

    const message = await channel.send({ embeds: [panelEmbed(player)], components: buildPanelComponents() });
    interaction.client.__panelMessageMap = interaction.client.__panelMessageMap ?? {};
    interaction.client.__panelMessageMap[interaction.guildId] = { channelId: channel.id, messageId: message.id };

    return interaction.reply({ embeds: [successEmbed('Panel Ready', `تم إرسال لوحة التحكم في <#${channel.id}>`)], ephemeral: true });
  }

  if (interaction.commandName === 'queue') return interaction.reply(queueResponse(player));

  if (interaction.commandName === 'nowplaying') {
    return interaction.reply({ embeds: [panelEmbed(player)], ephemeral: true });
  }

  if (interaction.commandName === 'disconnect') {
    musicManager.destroyPlayer(interaction.guildId);
    return interaction.reply({ embeds: [successEmbed('Disconnected', 'تم إخراج البوت من الروم الصوتي.')] });
  }

  return interaction.reply({ embeds: [errorEmbed('Unknown', 'أمر غير معروف.')], ephemeral: true });
};

export const handleRequestMessage = async (message, musicManager) => {
  if (message.author.bot) return false;
  if (!config.requestChannelId || message.channelId !== config.requestChannelId) return false;

  const gate = ensureVoice({ member: message.member });
  if (!gate.ok) {
    await message.reply({ embeds: [errorEmbed('Voice Required', 'ادخل روم صوتي أولاً ثم أرسل الأغنية.')] });
    return true;
  }

  const player = musicManager.getPlayer(message.guildId);
  const query = message.content.trim();
  if (!query) return true;

  await message.delete().catch(() => null);
  const searchingMsg = await message.channel.send({ embeds: [infoEmbed('Searching...', `جاري البحث عن: **${query}**`)] });

  try {
    await player.connect(gate.voiceChannel);
    const track = await player.enqueue(query, message.author.tag, message.author.id);
    await searchingMsg.edit({
      embeds: [successEmbed('Queued', `تمت إضافة **[${track.title}](${track.url})**\nالمدة: \`${track.duration}\``).setThumbnail(track.thumbnail ?? null)]
    });
  } catch {
    await searchingMsg.edit({ embeds: [errorEmbed('Search Failed', 'تعذر البحث/تشغيل الأغنية. جرب رابط آخر أو اسم مختلف.')] });
  }

  return true;
};
