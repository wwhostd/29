import { REST, Routes } from 'discord.js';
import { config, validateConfig } from '../src/config.js';
import { slashCommands } from '../src/commands/index.js';

validateConfig();

const rest = new REST({ version: '10' }).setToken(config.token);

const route = config.guildId
  ? Routes.applicationGuildCommands(config.clientId, config.guildId)
  : Routes.applicationCommands(config.clientId);

const scope = config.guildId ? `guild ${config.guildId}` : 'globally';

(async () => {
  try {
    console.log(`Deploying ${slashCommands.length} command(s) to ${scope}...`);
    await rest.put(route, { body: slashCommands });
    console.log('✅ Slash commands deployed successfully.');
  } catch (error) {
    console.error('❌ Failed to deploy slash commands:', error);
    process.exitCode = 1;
  }
})();
