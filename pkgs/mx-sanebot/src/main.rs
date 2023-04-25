mod msg_handler;

use std::env;

use matrix_sdk::{
    config::SyncSettings,
    room::Room,
    ruma::events::room::member::StrippedRoomMemberEvent,
    ruma::events::room::message::{
        MessageType, OriginalSyncRoomMessageEvent, RoomMessageEventContent,
    },
    Client,
};
use tokio::time::{sleep, Duration};

use msg_handler::MessageHandler;

async fn on_room_message(event: OriginalSyncRoomMessageEvent, room: Room) {
    println!("received event");
    if let Room::Joined(room) = room {
        let text_content = match event.content.msgtype {
            MessageType::Text(t) => t,
            _ => return, // not of interest
        };

        let sender = event.sender;
        let msg = text_content.body;
        println!("message from {sender}: {msg}\n");

        if sender.as_str() == "@sanebot:uninsane.org" {
            return; // don't respond to myself!
        }

        let resp = MessageHandler.on_msg(&msg);
        println!("response: {}", resp);

        let resp_content = RoomMessageEventContent::text_plain(&resp);

        // send our message to the room we found the "!ping" command in
        // the last parameter is an optional transaction id which we don't
        // care about.
        room.send(resp_content, None).await.unwrap();

        println!("response sent");
    }
}

// Whenever we see a new stripped room member event, we've asked our client to
// call this function. So what exactly are we doing then?
async fn on_stripped_state_member(
    room_member: StrippedRoomMemberEvent,
    client: Client,
    room: Room,
) {
    if room_member.state_key != client.user_id().unwrap() {
        // the invite we've seen isn't for us, but for someone else. ignore
        return;
    }

    // looks like the room is an invited room, let's attempt to join then
    if let Room::Invited(room) = room {
        // The event handlers are called before the next sync begins, but
        // methods that change the state of a room (joining, leaving a room)
        // wait for the sync to return the new room state so we need to spawn
        // a new task for them.
        tokio::spawn(async move {
            println!("Autojoining room {}", room.room_id());
            let mut delay = 2;

            while let Err(err) = room.accept_invitation().await {
                // retry autojoin due to synapse sending invites, before the
                // invited user can join for more information see
                // https://github.com/matrix-org/synapse/issues/4345
                eprintln!("Failed to join room {} ({err:?}), retrying in {delay}s", room.room_id());

                sleep(Duration::from_secs(delay)).await;
                delay *= 2;

                if delay > 3600 {
                    eprintln!("Can't join room {} ({err:?})", room.room_id());
                    break;
                }
            }
            println!("Successfully joined room {}", room.room_id());
        });
    }
}

async fn login_and_sync(
    homeserver_url: &str,
    username: &str,
    password: &str,
) -> anyhow::Result<()> {
    // TODO: look into caching the messages somewhere on disk (sled; indexeddb)
    let client = Client::builder()
        .homeserver_url(homeserver_url)
        .sled_store("/home/colin/mx-sanebot", None)?
        .build()
        .await?;
    println!("client built");
    client.login_username(&username, &password).initial_device_display_name("sanebot")
        .initial_device_display_name("sanebot")
        .send()
        .await?;

    println!("logged in as {username}");

    // Now, we want our client to react to invites. Invites sent us stripped member
    // state events so we want to react to them. We add the event handler before
    // the sync, so this happens also for older messages. All rooms we've
    // already entered won't have stripped states anymore and thus won't fire
    client.add_event_handler(on_stripped_state_member);

    // An initial sync to set up state and so our bot doesn't respond to old
    // messages. If the `StateStore` finds saved state in the location given the
    // initial sync will be skipped in favor of loading state from the store
    let response = client.sync_once(SyncSettings::default()).await.unwrap();
    println!("sync'd");
    // add our CommandBot to be notified of incoming messages, we do this after the
    // initial sync to avoid responding to messages before the bot was running.
    client.add_event_handler(on_room_message);

    // since we called `sync_once` before we entered our sync loop we must pass
    // that sync token to `sync`
    let settings = SyncSettings::default().token(response.next_batch);
    // this keeps state from the server streaming in to CommandBot via the
    // EventHandler trait
    client.sync(settings).await?;

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let password = env::var("SANEBOT_PASSWORD").unwrap_or("password".into());
    let result = login_and_sync("https://uninsane.org", "sanebot", &*password).await;
    println!("done");
    result
}
