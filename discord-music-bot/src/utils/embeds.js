import { EmbedBuilder } from 'discord.js';
import { formatDuration } from './player.js';

const baseEmbed = () => new EmbedBuilder().setColor(0x5865f2).setTimestamp();

export const infoEmbed = (title, description) => baseEmbed().setTitle(`🎵 ${title}`).setDescription(description);

export const errorEmbed = (title, description) =>
  baseEmbed().setColor(0xed4245).setTitle(`❌ ${title}`).setDescription(description);

export const successEmbed = (title, description) =>
  baseEmbed().setColor(0x57f287).setTitle(`✅ ${title}`).setDescription(description);

const progressBar = (percent) => {
  const size = 14;
  const clamped = Math.max(0, Math.min(1, percent));
  const pointer = Math.min(size - 1, Math.floor(clamped * size));
  return Array.from({ length: size }).map((_, i) => (i === pointer ? '🔘' : '▬')).join('');
};

export const panelEmbed = (player) => {
  const embed = baseEmbed().setTitle('🎛️ Professional Music Control Panel');
  if (!player?.current) {
    return embed
      .setDescription('لا يوجد تشغيل حالياً. استخدم **Add Song** أو ارسل رابط/اسم أغنية في روم الطلبات.')
      .addFields(
        { name: 'التحكم', value: 'Join • Leave • Pause • Resume • Skip • Stop • Vol +/-' },
        { name: 'البلاي ليست', value: 'Create / Add / Remove / Delete / List / Play Ordered / Shuffle' }
      );
  }

  const track = player.current;
  const p = player.getProgress();

  return embed
    .setDescription(`**Now Playing**\n[${track.title}](${track.url})`)
    .setThumbnail(track.thumbnail ?? null)
    .addFields(
      { name: 'Requested By', value: track.requestedBy ?? 'Unknown', inline: true },
      { name: 'Volume', value: `${Math.round(player.volume * 100)}%`, inline: true },
      { name: 'Queue', value: `${player.queue.length} track(s)`, inline: true },
      { name: 'Progress', value: `${progressBar(p.percent)}\n\`${formatDuration(p.elapsed)} / ${track.duration}\`` }
    );
};
