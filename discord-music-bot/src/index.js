import { Client, Events, GatewayIntentBits } from 'discord.js';
import { config, validateConfig } from './config.js';
import { handleCommand } from './commands/index.js';
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
  if (!interaction.isChatInputCommand()) return;

  try {
    await handleCommand(interaction, musicManager);
  } catch (error) {
    const payload = {
      content: 'حدث خطأ غير متوقع أثناء تنفيذ الأمر.',
      ephemeral: true
    };

    if (interaction.deferred || interaction.replied) {
      await interaction.followUp(payload);
      return;
    }

    await interaction.reply(payload);
  }
});

client.login(config.token);
