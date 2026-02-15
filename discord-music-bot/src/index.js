import { Client, Events, GatewayIntentBits } from 'discord.js';
import { config, validateConfig } from './config.js';
import {
  buildPanelComponents,
  handleCommand,
  handlePanelButton,
  handlePanelModal,
  handlePanelSelectMenu,
  handleRequestMessage
} from './commands/index.js';
import { panelEmbed } from './utils/embeds.js';
import { MusicManager } from './utils/player.js';

validateConfig();

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent]
});

const musicManager = new MusicManager(config.defaultVolume);

const refreshPanels = async () => {
  const map = client.__panelMessageMap ?? {};
  const entries = Object.entries(map);
  for (const [guildId, refs] of entries) {
    try {
      const guild = await client.guilds.fetch(guildId);
      const channel = await guild.channels.fetch(refs.channelId);
      if (!channel?.isTextBased()) continue;
      const msg = await channel.messages.fetch(refs.messageId);
      const player = musicManager.getPlayer(guildId);
      await msg.edit({ embeds: [panelEmbed(player)], components: buildPanelComponents() });
    } catch {
      // Ignore panel refresh failures per guild.
    }
  }
};

client.once(Events.ClientReady, (readyClient) => {
  console.log(`✅ Logged in as ${readyClient.user.tag}`);
  setInterval(refreshPanels, config.panelRefreshSeconds * 1000);
});

client.on(Events.MessageCreate, async (message) => {
  try {
    await handleRequestMessage(message, musicManager);
  } catch {
    await message.channel.send('حدث خطأ أثناء معالجة الطلب.').catch(() => null);
  }
});

client.on(Events.InteractionCreate, async (interaction) => {
  try {
    if (interaction.isButton()) {
      const handled = await handlePanelButton(interaction, musicManager);
      if (handled) return;
    }

    if (interaction.isStringSelectMenu()) {
      const handled = await handlePanelSelectMenu(interaction, musicManager);
      if (handled) return;
    }

    if (interaction.isModalSubmit()) {
      const handled = await handlePanelModal(interaction, musicManager);
      if (handled) return;
    }

    if (interaction.isChatInputCommand()) {
      await handleCommand(interaction, musicManager);
    }
  } catch {
    const payload = { content: 'حدث خطأ غير متوقع أثناء تنفيذ الأمر.', ephemeral: true };
    if (interaction.deferred || interaction.replied) {
      await interaction.followUp(payload).catch(() => null);
      return;
    }
    await interaction.reply(payload).catch(() => null);
  }
});

client.login(config.token);
