import { Client, Events, GatewayIntentBits } from 'discord.js';
import { config, validateConfig } from './config.js';
import { handleCommand, handlePanelButton, handlePanelModal } from './commands/index.js';
import { MusicManager } from './utils/player.js';

validateConfig();

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildVoiceStates
  ]
});

const musicManager = new MusicManager(config.defaultVolume);

client.once(Events.ClientReady, (readyClient) => {
  console.log(`✅ Logged in as ${readyClient.user.tag}`);
});

client.on(Events.InteractionCreate, async (interaction) => {
  try {
    if (interaction.isButton()) {
      const handled = await handlePanelButton(interaction, musicManager);
      if (handled) return;
    }

    if (interaction.isModalSubmit()) {
      const handled = await handlePanelModal(interaction, musicManager);
      if (handled) return;
    }

    if (interaction.isChatInputCommand()) {
      await handleCommand(interaction, musicManager);
      return;
    }
  } catch (error) {
    const payload = {
      content: 'حدث خطأ غير متوقع أثناء تنفيذ الأمر.',
      ephemeral: true
    };

    if (interaction.deferred || interaction.replied) {
      await interaction.followUp(payload).catch(() => null);
      return;
    }

    await interaction.reply(payload).catch(() => null);
  }
});

client.login(config.token);
