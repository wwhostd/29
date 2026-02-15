import { EmbedBuilder } from 'discord.js';

const baseEmbed = () =>
  new EmbedBuilder().setColor(0x5865f2).setTimestamp();

export const infoEmbed = (title, description) =>
  baseEmbed().setTitle(`🎵 ${title}`).setDescription(description);

export const errorEmbed = (title, description) =>
  baseEmbed().setColor(0xed4245).setTitle(`❌ ${title}`).setDescription(description);

export const successEmbed = (title, description) =>
  baseEmbed().setColor(0x57f287).setTitle(`✅ ${title}`).setDescription(description);
