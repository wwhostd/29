import dotenv from 'dotenv';

dotenv.config();

const toNumber = (value, fallback) => {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
};

export const config = {
  token: process.env.DISCORD_TOKEN,
  clientId: process.env.DISCORD_CLIENT_ID,
  guildId: process.env.DISCORD_GUILD_ID,
  panelChannelId: process.env.MUSIC_PANEL_CHANNEL_ID,
  requestChannelId: process.env.MUSIC_REQUEST_CHANNEL_ID,
  playlistManagerRoleId: process.env.PLAYLIST_MANAGER_ROLE_ID,
  panelRefreshSeconds: Math.max(5, toNumber(process.env.PANEL_REFRESH_SECONDS, 15)),
  defaultVolume: Math.max(0, Math.min(1, toNumber(process.env.DEFAULT_VOLUME, 0.6)))
};

export const validateConfig = () => {
  const missing = [];
  if (!config.token) missing.push('DISCORD_TOKEN');
  if (!config.clientId) missing.push('DISCORD_CLIENT_ID');

  if (missing.length > 0) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
};
