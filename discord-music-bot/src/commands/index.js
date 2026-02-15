import {
  SlashCommandBuilder,
  PermissionFlagsBits
} from 'discord.js';
import { errorEmbed, infoEmbed, successEmbed } from '../utils/embeds.js';

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
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
].map((command) => command.toJSON());

export const handleCommand = async (interaction, musicManager) => {
  const command = interaction.commandName;
  const guildId = interaction.guildId;
  const player = musicManager.getPlayer(guildId);

  if (command === 'play') {
    const gate = ensureVoice(interaction);
    if (!gate.ok) return interaction.reply(gate.reply);

    const query = interaction.options.getString('query', true);
    await interaction.deferReply();

    try {
      await player.connect(gate.voiceChannel);
      const track = await player.enqueue(query, interaction.user.tag);

      return interaction.editReply({
        embeds: [
          successEmbed(
            'Added to Queue',
            `**[${track.title}](${track.url})**\nالمدة: \`${track.duration}\`\nطلب بواسطة: **${track.requestedBy}**`
          ).setThumbnail(track.thumbnail ?? null)
        ]
      });
    } catch (error) {
      return interaction.editReply({
        embeds: [errorEmbed('Playback Error', 'تعذر تشغيل الأغنية. تأكد من الرابط أو جرّب اسم مختلف.')]
      });
    }
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
    return interaction.reply({
      embeds: [infoEmbed('Stopped', 'تم مسح الطابور وإيقاف الموسيقى.')]
    });
  }

  if (command === 'queue') {
    const now = player.current;
    const queued = player.getQueuePreview();

    if (!now && queued.length === 0) {
      return interaction.reply({
        embeds: [infoEmbed('Queue Empty', 'حالياً لا توجد أغانٍ في الطابور.')],
        ephemeral: true
      });
    }

    const lines = queued.map(
      (track, index) => `${index + 1}. [${track.title}](${track.url}) - \`${track.duration}\``
    );

    return interaction.reply({
      embeds: [
        infoEmbed(
          'Queue',
          `${now ? `**Now:** [${now.title}](${now.url}) - \`${now.duration}\`\n\n` : ''}${
            lines.join('\n') || 'لا توجد عناصر إضافية.'
          }`
        )
      ]
    });
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

    return interaction.reply({
      embeds: [successEmbed('Volume Updated', `تم ضبط الصوت إلى **${Math.round(updated * 100)}%**.`)]
    });
  }

  if (command === 'loop') {
    const enabled = player.toggleLoop();
    return interaction.reply({
      embeds: [infoEmbed('Loop Mode', enabled ? 'تم تفعيل التكرار للأغنية الحالية.' : 'تم تعطيل التكرار.')]
    });
  }

  if (command === 'disconnect') {
    musicManager.destroyPlayer(guildId);
    return interaction.reply({
      embeds: [successEmbed('Disconnected', 'تم إخراج البوت من الروم الصوتي.')]
    });
  }

  return interaction.reply({
    embeds: [errorEmbed('Unknown Command', 'هذا الأمر غير مدعوم حالياً.')],
    ephemeral: true
  });
};
