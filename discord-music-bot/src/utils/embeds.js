import { EmbedBuilder } from 'discord.js';

const baseEmbed = () =>
  new EmbedBuilder().setColor(0x5865f2).setTimestamp();

export const infoEmbed = (title, description) =>
  baseEmbed().setTitle(`🎵 ${title}`).setDescription(description);

export const errorEmbed = (title, description) =>
  baseEmbed().setColor(0xed4245).setTitle(`❌ ${title}`).setDescription(description);

export const successEmbed = (title, description) =>
  baseEmbed().setColor(0x57f287).setTitle(`✅ ${title}`).setDescription(description);

export const panelEmbed = () =>
  baseEmbed()
    .setTitle('🎧 Music Control Panel')
    .setDescription('لوحة التحكم الرئيسية للبوت.\n\nاستخدم الأزرار للتحكم السريع، أو زر **Add Song** لإضافة أغنية مباشرة.')
    .addFields(
      { name: 'تشغيل أغنية', value: 'Add Song', inline: true },
      { name: 'التحكم', value: 'Pause / Resume / Skip', inline: true },
      { name: 'الطابور', value: 'Queue / Stop', inline: true }
    );
