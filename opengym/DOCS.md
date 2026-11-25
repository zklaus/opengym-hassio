# openGym add-on

openGym, unmodified, at an HTTPS address of its own. This page takes you from installation
to a first workout, then explains the options and the messages in the log.

> **Status:** installation and the reverse proxy example below have been tried on one Home
> Assistant Green with the NGINX Home Assistant SSL proxy add-on and a wildcard certificate.
> The phone app, photo and video uploads, notifications and the AI Coach work through it.

## What you need first

- An HTTPS reverse proxy running **on this Home Assistant device**. The example here uses the
  official *NGINX Home Assistant SSL proxy* add-on.
- A hostname for openGym alone, for example `gym.example.org`, pointing to your home the same
  way your Home Assistant hostname does. A CNAME record to the Home Assistant hostname is the
  simplest: a changing home address then needs updating in one place only.
- A certificate that covers that hostname. A wildcard certificate (`*.example.org`) already
  does, if openGym's hostname is directly under it. Otherwise add the hostname to the
  certificate you have; with the Let's Encrypt add-on that is one more entry in `domains`.

openGym cannot be opened inside the Home Assistant sidebar, and it has no port on your home
network. That is on purpose: passkeys and the phone and watch apps need one stable HTTPS
address.

## Installation

1. **Install and set the address.** Install the add-on. On the Configuration tab, set
   *Public address* to the address people will use, for example `https://gym.example.org`.
2. **Turn on the Watchdog** on the Info tab, so that Home Assistant restarts openGym if it
   ever stops answering. Then start the add-on.
3. **Note the hostname** shown on the add-on's Info page (it looks like `abcd1234-opengym`).
   The reverse proxy forwards to it.
4. **Tell the reverse proxy about openGym.** For the NGINX Home Assistant SSL proxy add-on:
   set its option `customize.active` to `true`, and create the file
   `/share/nginx_proxy/opengym.conf`:

   ```nginx
   server {
       listen 443 ssl;
       server_name gym.example.org;              # your openGym hostname

       ssl_certificate     /ssl/fullchain.pem;   # must cover that hostname
       ssl_certificate_key /ssl/privkey.pem;

       # Photos and videos of custom exercises can be up to 112 MB.
       client_max_body_size 112m;

       location / {
           # Looked up when a request arrives, not when nginx starts, so that nginx (and
           # with it your access to Home Assistant) still starts while openGym is stopped.
           resolver 127.0.0.11 valid=30s;
           set $opengym http://abcd1234-opengym:8080;   # the hostname from step 3
           proxy_pass $opengym;

           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Forwarded-Proto $scheme;

           # The AI Coach streams its answers.
           proxy_buffering off;
           proxy_request_buffering off;
           proxy_read_timeout 300s;
           proxy_send_timeout 300s;
       }
   }
   ```

   Restart the NGINX add-on.
5. **Create your profile.** Open the public address on your phone, create a profile and
   register a passkey. The first profile on a new installation is the administrator.
6. **Close the door behind you.** Back on the add-on's Configuration tab, turn on
   *Invitation only* and restart the add-on. Until you do, anyone who finds the address can
   create a profile. Invitations are issued from *Settings → Account → Admin dashboard*.

## Options

| Option | What it does |
|---|---|
| Public address | The one https address of openGym. Required. A hostname, not an IP address, with nothing after it. Passkeys are tied to it: change it and everyone has to register a new passkey. |
| Invitation only | New profiles need an invitation from the administrator. Turn it on after creating your own profile (step 6). |
| Password sign-in | Lets people set a password next to their passkey. Off by default. Wrong passwords are throttled for the whole household, not per person, because openGym sees every visitor at the reverse proxy's address. |
| Contact for notification services | Optional e-mail address given to the push services that deliver notifications. If empty, they are given the public address. |

## Phone and watch apps

In the browser, signed in: *Settings → Account → Pair the mobile app* shows a one-time code.
Enter the public address and that code in the openGym app. Watches connect through the phone
app as openGym's own documentation describes.

## AI Coach

Optional, and off until the administrator sets it up. The Coach sends training data to an AI
provider of your choice and proposes plans from it. In this add-on it works with a provider
key (Anthropic, OpenAI, Google Gemini and others, or a model server of your own). The steps
for Anthropic:

1. Create an API key in the Anthropic Console (platform.claude.com). Buy a small amount of
   credit and leave automatic top-up off: the credit is then the most that can be spent.
2. In openGym: *Settings → Account → Admin dashboard*, the *AI Coach* card. Switch it on,
   choose **Anthropic API** (not *Claude (Anthropic)*, which this add-on cannot run), paste
   the key, use *List models* to pick a model, then *Test the Coach*.
3. Each person opens *Plan → Coach*, agrees to the consent screen and answers a few
   questions.

Worth knowing before you switch it on:

- **What leaves your device.** For a person who agreed: their plan, logged training, body
  weight, the answers they gave the Coach and whatever they type to it, sent to the provider
  under a pseudonym. Never names, sign-in data or another person's data. The consent screen
  lists it exactly, and openGym's own documentation (docs/AI_COACH.md) has the details.
- **One key for everybody.** Every profile uses the administrator's key and so the
  administrator's money. The daily limits on the same card bound it.
- **The key is stored on this device**, encrypted, and is part of backups (see below).

## Backups

The add-on is part of Home Assistant backups, with all profiles, workouts, uploads, passkeys
and pairings. It is stopped for the few seconds a backup takes. After restoring on another
device, point the public address at that device and everything works as before, without
signing in again.

The other device needs the reverse proxy as well: its add-on, the `share` folder with
`opengym.conf`, and the certificate in the `ssl` folder. A full backup carries all of them.
If you pick what to back up, check that the certificate is included; where the backup screen
does not offer the `ssl` folder, `ha backups new --folders ssl` in a terminal makes a backup
of it alone.

A backup also contains anything secret that openGym stores, such as an AI Coach provider key,
together with the key that unlocks it. Treat backups accordingly.

## What is on, what is off

Everything openGym offers inside the app works as upstream documents it, including personal
API tokens, the calendar feed and the AI Coach with a provider key. A calendar feed address or
an API token gives access to one profile without a passkey; that is how openGym designed them.

Not available in this add-on: guest mode, webhooks, sign-in through an identity provider, the
MCP server, and the AI Coach variants that run an AI program inside the container.

## Messages in the log

Lines from the add-on itself start with `[opengym-addon]`.

| Message | What to do |
|---|---|
| `The option "public_address" is not set` and similar | Set *Public address* as described above. |
| `Cannot write to the data folder` | The device is probably out of space. Free some and restart the add-on. |
| `The public address changed from … to …` | Passkeys made for the old address no longer work. Change it back, or have everyone register a new passkey. |
| `refused cross-origin …: origin="…" expected=…` | openGym was opened at an address other than the public address. Use the public address, or correct the option if the other one is right. Ignore the advice in that line about `ORIGIN` and `RP_ID`; in this add-on the option sets both. |
| `The openGym API stopped unexpectedly`, `The openGym web server (nginx) stopped unexpectedly` | The lines above it say why. With the Watchdog on, Home Assistant restarts the add-on. |

## Licences

The add-on's own files are MIT-licensed. openGym inside it is unmodified and under the GNU
AGPL v3.0; its source is at github.com/DuarteSantos8/openGym under the tag of the release
named in the changelog, and its licence and notices are in the image under
`/usr/share/doc/opengym/`. The exercise pictures and animations are © Gym visual, licensed
for use in openGym only: do not copy them out of the add-on; any other use needs your own
licence from gymvisual.com.

## Other add-ons on this device

openGym is reachable by other add-ons on the same Home Assistant, not by other devices on
your network. Add-ons are software you installed; if you run one you do not trust, leave
password sign-in off.
