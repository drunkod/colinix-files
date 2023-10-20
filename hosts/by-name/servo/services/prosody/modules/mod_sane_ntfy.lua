-- simple proof-of-concept Prosody module
-- module development guide: <https://prosody.im/doc/developers/modules>
-- module API docs: <https://prosody.im/doc/developers/moduleapi>
--
-- much of this code is lifted from Prosody's own `mod_cloud_notify`

local jid = require"util.jid";

module:log("info", "initialized");

local function is_urgent(stanza)
  if stanza.name == "message" then
    if stanza:get_child("propose", "urn:xmpp:jingle-message:0") then
      return true, "jingle call";
    end
  end
end


local function archive_message_added(event)
  -- event is: { origin = origin, stanza = stanza, for_user = store_user, id = id }
  local stanza = event.stanza;
  local to = stanza.attr.to;
  to = to and jid.split(to) or event.origin.username;

  -- only notify if the stanza destination is the mam user we store it for
  if event.for_user == to then
    local is_urgent_stanza, urgent_reason = is_urgent(event.stanza);

    if is_urgent_stanza then
      module:log("info", "Urgent push for %s (%s) (TODO: bridge to ntfy)", to, urgent_reason);
    end
  end
end


module:hook("archive-message-added", archive_message_added);
