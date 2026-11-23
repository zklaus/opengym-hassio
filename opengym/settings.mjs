// Turns the add-on's options into upstream's documented settings.
// Usage: node settings.mjs /data/options.json
// Prints NAME=value lines on success. On unusable options, prints one plain sentence to
// stderr and exits 1. (docs/architecture.md C3; requirements FR-1, FR-2, FR-4.)
import { readFileSync } from 'node:fs';
import { isIP } from 'node:net';

function fail(message) {
  console.error(`[opengym-addon] ${message}`);
  process.exit(1);
}

const EXAMPLE = 'for example https://gym.example.org';

let options;
try {
  options = JSON.parse(readFileSync(process.argv[2], 'utf8'));
} catch (e) {
  fail(`Cannot read the add-on options (${process.argv[2]}): ${e.message}`);
}

const address = typeof options.public_address === 'string' ? options.public_address.trim() : '';
if (!address) {
  fail(`The option "public_address" is not set. Set it to the https address people open openGym at, ${EXAMPLE}.`);
}

let url;
try {
  url = new URL(address);
} catch {
  fail(`"public_address" is "${address}", which is not an address. Use the form https://hostname, ${EXAMPLE}.`);
}
if (url.protocol !== 'https:') {
  fail(`"public_address" is "${address}", but it has to start with https://. openGym is only served over HTTPS, ${EXAMPLE}.`);
}
if (isIP(url.hostname.replace(/^\[|\]$/g, ''))) {
  fail(`"public_address" is "${address}", an IP address. Passkeys need a hostname, ${EXAMPLE}.`);
}
if (url.username || url.password || url.search || url.hash || url.pathname !== '/') {
  fail(`"public_address" is "${address}", but it must be only https:// and a hostname, with nothing after it, ${EXAMPLE}.`);
}

const contact = typeof options.notification_contact === 'string' ? options.notification_contact.trim() : '';
if (contact && !/^[^\s@]+@[^\s@]+$/.test(contact)) {
  fail(`"notification_contact" is "${contact}", which is not an e-mail address. Leave it empty or use the form you@example.org.`);
}

const settings = {
  ORIGIN: url.origin,
  RP_ID: url.hostname,
  INVITE_ONLY: options.invite_only === true ? '1' : '0',
  PASSWORD_LOGIN: options.password_login === true ? '1' : '0',
};
if (contact) settings.VAPID_SUBJECT = `mailto:${contact}`;

for (const [name, value] of Object.entries(settings)) console.log(`${name}=${value}`);
