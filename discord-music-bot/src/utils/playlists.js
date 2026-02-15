import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const DATA_DIR = path.resolve(process.cwd(), 'data');
const DB_FILE = path.join(DATA_DIR, 'playlists.json');

const ensureDb = () => {
  if (!existsSync(DATA_DIR)) mkdirSync(DATA_DIR, { recursive: true });
  if (!existsSync(DB_FILE)) writeFileSync(DB_FILE, JSON.stringify({ guilds: {} }, null, 2));
};

const readDb = () => {
  ensureDb();
  return JSON.parse(readFileSync(DB_FILE, 'utf8'));
};

const writeDb = (db) => {
  ensureDb();
  writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
};

const getGuildRoot = (db, guildId) => {
  if (!db.guilds[guildId]) db.guilds[guildId] = { playlists: {} };
  return db.guilds[guildId];
};

export class PlaylistStore {
  createPlaylist(guildId, name, ownerId) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    const key = name.trim().toLowerCase();
    if (root.playlists[key]) throw new Error('Playlist already exists.');

    root.playlists[key] = {
      name: name.trim(),
      ownerId,
      tracks: []
    };

    writeDb(db);
    return root.playlists[key];
  }

  deletePlaylist(guildId, name) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    const key = name.trim().toLowerCase();
    if (!root.playlists[key]) throw new Error('Playlist not found.');

    delete root.playlists[key];
    writeDb(db);
  }

  listPlaylists(guildId) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    return Object.values(root.playlists);
  }

  getPlaylist(guildId, name) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    return root.playlists[name.trim().toLowerCase()] ?? null;
  }

  addTrack(guildId, name, track) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    const key = name.trim().toLowerCase();
    if (!root.playlists[key]) throw new Error('Playlist not found.');

    root.playlists[key].tracks.push({
      title: track.title,
      url: track.url,
      duration: track.duration,
      durationInSec: track.durationInSec,
      thumbnail: track.thumbnail
    });

    writeDb(db);
    return root.playlists[key];
  }

  removeTrack(guildId, name, index) {
    const db = readDb();
    const root = getGuildRoot(db, guildId);
    const key = name.trim().toLowerCase();
    const playlist = root.playlists[key];
    if (!playlist) throw new Error('Playlist not found.');
    if (index < 0 || index >= playlist.tracks.length) throw new Error('Track index out of range.');

    const [removed] = playlist.tracks.splice(index, 1);
    writeDb(db);
    return removed;
  }
}
