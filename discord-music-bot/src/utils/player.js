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
const SC_URL_REGEX = /^(https?:\/\/)?(www\.)?soundcloud\.com\/.+/i;

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

const shuffleArray = (arr) => {
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

class GuildMusicPlayer {
  constructor(guildId, defaultVolume = 0.6) {
    this.guildId = guildId;
    this.defaultVolume = defaultVolume;
    this.queue = [];
    this.current = null;
    this.currentStartedAt = null;
    this.volume = defaultVolume;
    this.loop = false;
    this.trackOwnerId = null;

    this.audioPlayer = createAudioPlayer({
      behaviors: { noSubscriber: NoSubscriberBehavior.Pause }
    });

    this.audioPlayer.on(AudioPlayerStatus.Playing, () => {
      this.currentStartedAt = Date.now();
    });

    this.audioPlayer.on(AudioPlayerStatus.Idle, async () => {
      if (this.loop && this.current) this.queue.unshift(this.current);
      this.current = null;
      this.currentStartedAt = null;
      this.trackOwnerId = null;
      await this.processQueue();
    });

    this.audioPlayer.on('error', async () => {
      this.current = null;
      this.currentStartedAt = null;
      this.trackOwnerId = null;
      await this.processQueue();
    });
  }

  async connect(voiceChannel) {
    if (this.connection && this.connection.joinConfig.channelId === voiceChannel.id) return;

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

  async enqueue(query, requestedBy, requestedById) {
    const track = await this.resolveTrack(query, requestedBy, requestedById);
    this.queue.push(track);
    if (!this.current) await this.processQueue();
    return track;
  }

  async enqueueMany(tracks) {
    this.queue.push(...tracks);
    if (!this.current) await this.processQueue();
  }

  async resolveTrack(rawQuery, requestedBy, requestedById) {
    const query = normalizeQuery(rawQuery);

    if (YT_URL_REGEX.test(query)) {
      const info = await play.video_basic_info(query);
      const d = info.video_details;
      return {
        title: d.title,
        url: d.url,
        duration: formatDuration(d.durationInSec),
        durationInSec: Number(d.durationInSec) || 0,
        thumbnail: d.thumbnails?.[0]?.url,
        requestedBy,
        requestedById
      };
    }

    if (SC_URL_REGEX.test(query)) {
      const info = await play.soundcloud(query);
      return {
        title: info.name,
        url: info.url,
        duration: formatDuration(info.durationInSec),
        durationInSec: Number(info.durationInSec) || 0,
        thumbnail: info.thumbnail,
        requestedBy,
        requestedById
      };
    }

    const [yt] = await play.search(query, { limit: 1, source: { youtube: 'video' } });
    const [sc] = await play.search(query, { limit: 1, source: { soundcloud: 'tracks' } });
    const best = yt ?? sc;
    if (!best) throw new Error('No matching track found.');

    return {
      title: best.title,
      url: best.url,
      duration: formatDuration(best.durationInSec),
      durationInSec: Number(best.durationInSec) || 0,
      thumbnail: best.thumbnails?.[0]?.url,
      requestedBy,
      requestedById
    };
  }

  async processQueue() {
    if (this.current || this.queue.length === 0) return;

    const nextTrack = this.queue.shift();
    this.current = nextTrack;
    this.trackOwnerId = nextTrack.requestedById ?? null;

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
    } catch {
      this.current = null;
      this.currentStartedAt = null;
      this.trackOwnerId = null;
      await this.processQueue();
    }
  }

  canControl(userId) {
    if (!this.trackOwnerId) return true;
    return this.trackOwnerId === userId;
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
    this.currentStartedAt = null;
    this.trackOwnerId = null;
    this.audioPlayer.stop(true);
  }

  setVolume(nextVolume) {
    this.volume = Math.max(0, Math.min(2, nextVolume));
    const resource = this.audioPlayer.state.resource;
    if (resource?.volume) resource.volume.setVolume(this.volume);
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

  getProgress() {
    if (!this.current || !this.current.durationInSec || !this.currentStartedAt) {
      return { elapsed: 0, total: this.current?.durationInSec ?? 0, percent: 0 };
    }

    const elapsed = Math.max(0, Math.floor((Date.now() - this.currentStartedAt) / 1000));
    const total = this.current.durationInSec;
    return {
      elapsed: Math.min(elapsed, total),
      total,
      percent: total > 0 ? Math.min(1, elapsed / total) : 0
    };
  }

  enqueuePlaylist(tracks, mode = 'ordered', requestedBy, requestedById) {
    const mapped = tracks.map((track) => ({ ...track, requestedBy, requestedById }));
    const batch = mode === 'shuffle' ? shuffleArray(mapped) : mapped;
    this.queue.push(...batch);
    if (!this.current) {
      return this.processQueue();
    }
    return Promise.resolve();
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
    if (!player) return;
    player.disconnect();
    this.players.delete(guildId);
  }
}

export { formatDuration };
