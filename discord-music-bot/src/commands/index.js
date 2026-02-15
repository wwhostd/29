import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  ModalBuilder,
  PermissionFlagsBits,
  SlashCommandBuilder,
  TextInputBuilder,
  TextInputStyle
} from 'discord.js';
import { config } from '../config.js';
import { errorEmbed, infoEmbed, panelEmbed, successEmbed } from '../utils/embeds.js';

export const PANEL_IDS = {
  message: 'music:panel:message',
  add: 'music:panel:add',
  pause: 'music:panel:pause',
  resume: 'music:panel:resume',
  skip: 'music:panel:skip',
  queue: 'music:panel:queue',
  stop: 'music:panel:stop',
  modal: 'music:panel:add-modal',
  modalQuery: 'music:panel:add-modal-query'
};

const ensureVoice = (interaction) => {
  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) {
    return {
      ok: false,
      reply: {
        embeds: [errorEmbed('Voice Channel Required', 'ادخل روم صوتي اولاً وبعدها جرّب الأمر.')],
        ephemeral: true
      }
    };
  }

  return { ok: true, voiceChannel };
};

const queueResponse = (player) => {
  const now = player.current;
  const queued = player.getQueuePreview();

  if (!now && queued.length === 0) {
    return {
      embeds: [infoEmbed('Queue Empty', 'حالياً لا توجد أغانٍ في الطابور.')],
      ephemeral: true
    };
  }

  const lines = queued.map(
    (track, index) => `${index + 1}. [${track.title}](${track.url}) - \`${track.duration}\``
  );

  return {
    embeds: [
      infoEmbed(
        'Queue',
        `${now ? `**Now:** [${now.title}](${now.url}) - \`${now.duration}\`\n\n` : ''}${
          lines.join('\n') || 'لا توجد عناصر إضافية.'
        }`
      )
    ]
  };
};

export const buildPanelComponents = () => {
  const row1 = new ActionRowBuilder().addComponents(
    new ButtonBuilder().setCustomId(PANEL_IDS.add).setLabel('Add Song').setStyle(ButtonStyle.Success).setEmoji('➕'),
    new ButtonBuilder().setCustomId(PANEL_IDS.pause).setLabel('Pause').setStyle(ButtonStyle.Secondary).setEmoji('⏸️'),
    new ButtonBuilder().setCustomId(PANEL_IDS.resume).setLabel('Resume').setStyle(ButtonStyle.Secondary).setEmoji('▶️')
  );

  const row2 = new ActionRowBuilder().addComponents(
    new ButtonBuilder().setCustomId(PANEL_IDS.skip).setLabel('Skip').setStyle(ButtonStyle.Primary).setEmoji('⏭️'),
    new ButtonBuilder().setCustomId(PANEL_IDS.queue).setLabel('Queue').setStyle(ButtonStyle.Primary).setEmoji('📜'),
    new ButtonBuilder().setCustomId(PANEL_IDS.stop).setLabel('Stop').setStyle(ButtonStyle.Danger).setEmoji('⏹️')
  );

  return [row1, row2];
};

const enqueueTrack = async (interaction, player, query) => {
  const gate = ensureVoice(interaction);
  if (!gate.ok) {
    return gate.reply;
  }

  try {
    await player.connect(gate.voiceChannel);
    const track = await player.enqueue(query, interaction.user.tag);

    return {
      embeds: [
        successEmbed(
          'Added to Queue',
          `**[${track.title}](${track.url})**\nالمدة: \`${track.duration}\`\nطلب بواسطة: **${track.requestedBy}**`
        ).setThumbnail(track.thumbnail ?? null)
      ]
    };
  } catch {
    return {
      embeds: [errorEmbed('Playback Error', 'تعذر تشغيل الأغنية. تأكد من الرابط أو جرّب اسم مختلف.')],
      ephemeral: true
    };
  }
};

export const handlePanelButton = async (interaction, musicManager) => {
  if (!Object.values(PANEL_IDS).includes(interaction.customId)) return false;

  const player = musicManager.getPlayer(interaction.guildId);

  if (config.panelChannelId && interaction.channelId !== config.panelChannelId) {
    await interaction.reply({
      embeds: [errorEmbed('Panel Channel Only', 'استخدم لوحة التحكم المخصصة في الروم المحدد فقط.')],
      ephemeral: true
    });
    return true;
  }

  if (interaction.customId === PANEL_IDS.add) {
    const modal = new ModalBuilder().setCustomId(PANEL_IDS.modal).setTitle('Add Song');
    const queryInput = new TextInputBuilder()
      .setCustomId(PANEL_IDS.modalQuery)
      .setLabel('رابط YouTube أو اسم الأغنية')
      .setPlaceholder('مثال: Eminem - Mockingbird')
      .setStyle(TextInputStyle.Short)
      .setRequired(true)
      .setMaxLength(200);

    modal.addComponents(new ActionRowBuilder().addComponents(queryInput));
    await interaction.showModal(modal);
    return true;
  }

  if (interaction.customId === PANEL_IDS.pause) {
    const success = player.pause();
    await interaction.reply({
      embeds: [success ? infoEmbed('Paused', 'تم إيقاف التشغيل مؤقتاً.') : errorEmbed('Pause Failed', 'لا يوجد شيء قيد التشغيل.')],
      ephemeral: !success
    });
    return true;
  }

  if (interaction.customId === PANEL_IDS.resume) {
    const success = player.resume();
    await interaction.reply({
      embeds: [success ? successEmbed('Resumed', 'تم استكمال التشغيل.') : errorEmbed('Resume Failed', 'لا يوجد تشغيل موقوف.')],
      ephemeral: !success
    });
    return true;
  }

  if (interaction.customId === PANEL_IDS.skip) {
    const success = player.skip();
    await interaction.reply({
      embeds: [success ? infoEmbed('Skipped', 'تم تخطي الأغنية الحالية.') : errorEmbed('Skip Failed', 'لا يوجد تشغيل حالياً.')],
      ephemeral: !success
    });
    return true;
  }

  if (interaction.customId === PANEL_IDS.queue) {
    await interaction.reply(queueResponse(player));
    return true;
  }

  if (interaction.customId === PANEL_IDS.stop) {
    player.stop();
    await interaction.reply({ embeds: [infoEmbed('Stopped', 'تم مسح الطابور وإيقاف الموسيقى.')] });
    return true;
  }

  return false;
};

export const handlePanelModal = async (interaction, musicManager) => {
  if (interaction.customId !== PANEL_IDS.modal) return false;

  const player = musicManager.getPlayer(interaction.guildId);
  const query = interaction.fields.getTextInputValue(PANEL_IDS.modalQuery);
  const payload = await enqueueTrack(interaction, player, query);
  await interaction.reply(payload);
  return true;
};

export const slashCommands = [
  new SlashCommandBuilder()
    .setName('play')
    .setDescription('تشغيل أغنية من YouTube عبر الرابط أو الاسم.')
    .addStringOption((option) =>
      option
        .setName('query')
        .setDescription('الرابط أو اسم الأغنية')
        .setRequired(true)
    ),
  new SlashCommandBuilder().setName('pause').setDescription('إيقاف مؤقت.'),
  new SlashCommandBuilder().setName('resume').setDescription('استكمال التشغيل.'),
  new SlashCommandBuilder().setName('skip').setDescription('تخطي الأغنية الحالية.'),
  new SlashCommandBuilder().setName('stop').setDescription('إيقاف البوت ومسح الطابور.'),
  new SlashCommandBuilder().setName('queue').setDescription('عرض قائمة الانتظار.'),
  new SlashCommandBuilder().setName('nowplaying').setDescription('الأغنية الحالية.'),
  new SlashCommandBuilder()
    .setName('volume')
    .setDescription('تغيير الصوت من 0 إلى 200%.')
    .addIntegerOption((option) =>
      option
        .setName('percent')
        .setDescription('مثال: 100')
        .setRequired(true)
        .setMinValue(0)
        .setMaxValue(200)
    ),
  new SlashCommandBuilder().setName('loop').setDescription('تفعيل/تعطيل تكرار الأغنية الحالية.'),
  new SlashCommandBuilder()
    .setName('disconnect')
    .setDescription('إخراج البوت من الروم الصوتي.')
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),
  new SlashCommandBuilder()
    .setName('setup-panel')
    .setDescription('إنشاء بانل التحكم الموسيقي داخل الروم المخصص.')
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
].map((command) => command.toJSON());

export const handleCommand = async (interaction, musicManager) => {
  const command = interaction.commandName;
  const guildId = interaction.guildId;
  const player = musicManager.getPlayer(guildId);

  if (command === 'play') {
    await interaction.deferReply();
    const query = interaction.options.getString('query', true);
    return interaction.editReply(await enqueueTrack(interaction, player, query));
  }

  if (command === 'setup-panel') {
    if (!config.panelChannelId) {
      return interaction.reply({
        embeds: [errorEmbed('Missing Config', 'حدد `MUSIC_PANEL_CHANNEL_ID` داخل ملف `.env` أولاً.')],
        ephemeral: true
      });
    }

    const channel = await interaction.guild.channels.fetch(config.panelChannelId).catch(() => null);
    if (!channel?.isTextBased()) {
      return interaction.reply({
        embeds: [errorEmbed('Invalid Channel', 'تعذر الوصول إلى روم البانل. تأكد من ID وصلاحيات البوت.')],
        ephemeral: true
      });
    }

    await channel.send({
      embeds: [panelEmbed()],
      components: buildPanelComponents()
    });

    return interaction.reply({
      embeds: [successEmbed('Panel Created', `تم إرسال لوحة التحكم بنجاح في <#${config.panelChannelId}>`)],
      ephemeral: true
    });
  }

  if (command === 'pause') {
    const success = player.pause();
    return interaction.reply({
      embeds: [success ? infoEmbed('Paused', 'تم إيقاف التشغيل مؤقتاً.') : errorEmbed('Pause Failed', 'لا يوجد شيء قيد التشغيل.')],
      ephemeral: !success
    });
  }

  if (command === 'resume') {
    const success = player.resume();
    return interaction.reply({
      embeds: [success ? successEmbed('Resumed', 'تم استكمال التشغيل.') : errorEmbed('Resume Failed', 'لا يوجد تشغيل موقوف.')],
      ephemeral: !success
    });
  }

  if (command === 'skip') {
    const success = player.skip();
    return interaction.reply({
      embeds: [success ? infoEmbed('Skipped', 'تم تخطي الأغنية الحالية.') : errorEmbed('Skip Failed', 'لا يوجد تشغيل حالياً.')],
      ephemeral: !success
    });
  }

  if (command === 'stop') {
    player.stop();
    return interaction.reply({ embeds: [infoEmbed('Stopped', 'تم مسح الطابور وإيقاف الموسيقى.')] });
  }

  if (command === 'queue') {
    return interaction.reply(queueResponse(player));
  }

  if (command === 'nowplaying') {
    if (!player.current) {
      return interaction.reply({
        embeds: [infoEmbed('Nothing Playing', 'لا يوجد شيء قيد التشغيل حالياً.')],
        ephemeral: true
      });
    }

    const current = player.current;
    return interaction.reply({
      embeds: [
        infoEmbed(
          'Now Playing',
          `**[${current.title}](${current.url})**\nالمدة: \`${current.duration}\`\nطلب بواسطة: **${current.requestedBy}**`
        ).setThumbnail(current.thumbnail ?? null)
      ]
    });
  }

  if (command === 'volume') {
    const percent = interaction.options.getInteger('percent', true);
    const updated = player.setVolume(percent / 100);
    return interaction.reply({ embeds: [successEmbed('Volume Updated', `تم ضبط الصوت إلى **${Math.round(updated * 100)}%**.`)] });
  }

  if (command === 'loop') {
    const enabled = player.toggleLoop();
    return interaction.reply({ embeds: [infoEmbed('Loop Mode', enabled ? 'تم تفعيل التكرار للأغنية الحالية.' : 'تم تعطيل التكرار.')] });
  }

  if (command === 'disconnect') {
    musicManager.destroyPlayer(guildId);
    return interaction.reply({ embeds: [successEmbed('Disconnected', 'تم إخراج البوت من الروم الصوتي.')] });
  }

  return interaction.reply({
    embeds: [errorEmbed('Unknown Command', 'هذا الأمر غير مدعوم حالياً.')],
    ephemeral: true
  });
};
