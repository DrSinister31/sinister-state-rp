import net from 'net';
import dotenv from 'dotenv';
dotenv.config();

export const BYTE_COMMANDS: Record<string, number> = {
  announce: 0x10,
  directmessage: 0x11,
  serverdetails: 0x12,
  wipecorpses: 0x13,
  getplayables: 0x14,
  updateplayables: 0x15,
  togglemigrations: 0x19,
  ban: 0x20,
  togglegrowthmultiplier: 0x21,
  setgrowthmultiplier: 0x22,
  togglenetupdatedistancechecks: 0x23,
  kick: 0x30,
  playerlist: 0x40,
  save: 0x50,
  pause: 0x60,
  playerdata: 0x77,
  getplayerdata: 0x77,
  togglewhitelist: 0x81,
  addwhitelist: 0x82,
  removewhitelist: 0x83,
  toggleglobalchat: 0x84,
  togglehumans: 0x86,
  toggleai: 0x90,
  disableaiclasses: 0x91,
  aidensity: 0x92,
  getqueuestatus: 0x93,
  toggleailearning: 0x94,
  custom: 0x70,
};

function parseResponse(response: string): { executed: boolean; message: string } {
  const saved = response.match(/Game saved/i);
  if (saved) return { executed: true, message: 'Game saved' };
  const announced = response.match(/Announcement Sent/i);
  if (announced) return { executed: true, message: 'Announcement sent' };
  const corpses = response.match(/Corpses wiped/i);
  if (corpses) return { executed: true, message: 'Corpses wiped' };
  const success = response.match(/execute result\s*:\s*Success/i);
  if (success) return { executed: true, message: response.trim() };
  const resultMatch = response.match(/execute result\s*:\s*(True|False)/i);
  if (resultMatch) return { executed: resultMatch[1].toLowerCase() === 'true', message: response.trim() };
  return { executed: response.length > 0 && !response.toLowerCase().includes('error'), message: response.trim() };
}

export function runRcon(command: string): Promise<string> {
  const host = process.env.RCON_HOST;
  const port = parseInt(process.env.RCON_PORT || '2463');
  const password = process.env.RCON_PASSWORD;

  if (!host || !password) {
    return Promise.resolve('❌ Error: RCON credentials not configured in .env');
  }

  const raw = command.trim();
  if (!raw) return Promise.resolve('❌ Error: command is required');

  const cmdLower = raw.split(' ')[0].toLowerCase();
  const knownByte = BYTE_COMMANDS[cmdLower] !== undefined ? BYTE_COMMANDS[cmdLower] : undefined;

  let cmdByte: number;
  let args: string;

  if (knownByte !== undefined && knownByte !== 0x70) {
    cmdByte = knownByte;
    args = raw.substring(cmdLower.length).trim();
  } else {
    cmdByte = 0x70;
    args = raw;
  }

  return new Promise((resolve) => {
    const socket = new net.Socket();
    socket.setTimeout(12000);
    let resolved = false;
    const chunks: string[] = [];

    const finish = (text: string) => {
      if (!resolved) {
        resolved = true;
        socket.destroy();
        resolve(text);
      }
    };

    socket.connect(port, host, () => {
      socket.write(Buffer.concat([Buffer.from([0x01]), Buffer.from(password, 'utf-8'), Buffer.from([0x00])]));
    });

    socket.on('data', (data) => {
      const txt = data.toString('utf-8');
      if (txt.includes('Accepted') || txt.includes('accepted')) {
        socket.removeAllListeners('data');
        socket.on('data', (d) => {
          chunks.push(d.toString('utf-8'));
        });
        const pkt = Buffer.concat([Buffer.from([0x02, cmdByte]), Buffer.from(args, 'utf-8'), Buffer.from([0x00])]);
        socket.write(pkt);
        setTimeout(() => finish(chunks.join('')), 3000);
      } else if (txt.includes('incorrect') || txt.includes('denied')) {
        finish(txt);
      }
    });

    socket.on('error', (err) => {
      if (!resolved) finish(`Socket Error: ${err.message}`);
    });
    socket.on('timeout', () => {
      if (!resolved) finish('Connection timed out');
    });
  });
}
