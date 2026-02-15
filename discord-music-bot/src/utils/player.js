import {
  AudioPlayerStatus,
  NoSubscriberBehavior,
  VoiceConnectionStatus,
  createAudioPlayer,
  createAudioResource,
  entersState,
  joinVoiceChannel
} from '@discordjs/voice';
import play from 'play-dl';

const YT_URL_REGEX = /^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/i;

const normalizeQuery = (query) => query.trim();

const formatDuration = (seconds) => {
  if (!Number.isFinite(seconds) || seconds <= 0) return 'Live';

  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);

  return [h, m, s]
    .filter((value, index) => value > 0 || index > 0)
    .map((value) => String(value).padStart(2, '0'))
    .join(':');
};

class GuildMusicPlayer {
  constructor(guildId, defaultVolume = 0.6) {
    this.guildId = guildId;
    this.defaultVolume = defaultVolume;
    this.queue = [];
    this.current = null;
    this.volume = defaultVolume;
    this.loop = false;

    this.audioPlayer = createAudioPlayer({
      behaviors: {
        noSubscriber: NoSubscriberBehavior.Pause
      }
    });

    this.audioPlayer.on(AudioPlayerStatus.Idle, async () => {
      if (this.loop && this.current) {
        this.queue.unshift(this.current);
      }
      this.current = null;
      await this.processQueue();
    });

    this.audioPlayer.on('error', async () => {
      this.current = null;
      await this.processQueue();
    });
  }

  async connect(voiceChannel) {
    if (
      this.connection &&
      this.connection.joinConfig.channelId === voiceChannel.id
    ) {
      return;
    }

    if (this.connection) {
      this.connection.destroy();
      this.connection = null;
    }

    this.connection = joinVoiceChannel({
      channelId: voiceChannel.id,
      guildId: voiceChannel.guild.id,
      adapterCreator: voiceChannel.guild.voiceAdapterCreator,
      selfDeaf: true
    });

    this.connection.subscribe(this.audioPlayer);

    await entersState(this.connection, VoiceConnectionStatus.Ready, 20_000);
  }

  async enqueue(query, requestedBy) {
    const track = await this.resolveTrack(query, requestedBy);
    this.queue.push(track);

    if (!this.current) {
      await this.processQueue();
    }

    return track;
  }

  async resolveTrack(rawQuery, requestedBy) {
    const query = normalizeQuery(rawQuery);

    if (YT_URL_REGEX.test(query)) {
      const info = await play.video_basic_info(query);
      const details = info.video_details;
      return {
        title: details.title,
        url: details.url,
        duration: formatDuration(details.durationInSec),
        thumbnail: details.thumbnails?.[0]?.url,
        requestedBy
      };
    }

    const searchResult = await play.search(query, { limit: 1, source: { youtube: 'video' } });

    if (!searchResult.length) {
      throw new Error('No matching track found.');
    }

    const result = searchResult[0];
    return {
      title: result.title,
      url: result.url,
      duration: formatDuration(result.durationInSec),
      thumbnail: result.thumbnails?.[0]?.url,
      requestedBy
    };
  }

  async processQueue() {
    if (this.current || this.queue.length === 0) {
      return;
    }

    const nextTrack = this.queue.shift();
    this.current = nextTrack;

    try {
      const stream = await play.stream(nextTrack.url, {
        discordPlayerCompatibility: true,
        quality: 2
      });

      const resource = createAudioResource(stream.stream, {
        inputType: stream.type,
        inlineVolume: true
      });

      resource.volume.setVolume(this.volume);
      this.audioPlayer.play(resource);
    } catch (error) {
      this.current = null;
      await this.processQueue();
    }
  }

  pause() {
    return this.audioPlayer.pause();
  }

  resume() {
    return this.audioPlayer.unpause();
  }

  skip() {
    return this.audioPlayer.stop();
  }

  stop() {
    this.queue = [];
    this.current = null;
    this.audioPlayer.stop(true);
  }

  setVolume(nextVolume) {
    this.volume = Math.max(0, Math.min(2, nextVolume));
    const resource = this.audioPlayer.state.resource;
    if (resource?.volume) {
      resource.volume.setVolume(this.volume);
    }
    return this.volume;
  }

  toggleLoop() {
    this.loop = !this.loop;
    return this.loop;
  }

  disconnect() {
    this.stop();
    if (this.connection) {
      this.connection.destroy();
      this.connection = null;
    }
  }

  getQueuePreview(limit = 10) {
    return this.queue.slice(0, limit);
  }
}

export class MusicManager {
  constructor(defaultVolume = 0.6) {
    this.players = new Map();
    this.defaultVolume = defaultVolume;
  }

  getPlayer(guildId) {
    if (!this.players.has(guildId)) {
      this.players.set(guildId, new GuildMusicPlayer(guildId, this.defaultVolume));
    }

    return this.players.get(guildId);
  }

  destroyPlayer(guildId) {
    const player = this.players.get(guildId);
    if (player) {
      player.disconnect();
      this.players.delete(guildId);
    }
  }
}
