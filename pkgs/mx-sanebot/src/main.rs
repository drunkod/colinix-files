mod msg_handler;

use std::env;

use futures::StreamExt as _;
use matrix_sdk::{
    config::SyncSettings,
    room::Room,
    Client,
};
use matrix_sdk::ruma::RoomId;
use matrix_sdk::ruma::events::{
    AnySyncMessageLikeEvent,
    AnySyncTimelineEvent,
    SyncMessageLikeEvent,
};
use matrix_sdk::ruma::events::room::member::StrippedRoomMemberEvent;
use matrix_sdk::ruma::events::room::message::{
    MessageType,
    RoomMessageEventContent,
};
use tokio::time::{sleep, Duration};

use msg_handler::MessageHandler;

#[derive(Clone)]
struct Runner {
    // this is actually a *handle* to the client (Arc).
    client: Client,
}

impl Runner {
    async fn login(
        homeserver: &str,
        username: &str,
        password: &str,
    ) -> anyhow::Result<Self> {
        // TODO: look into caching the messages somewhere on disk (sled; indexeddb)
        let client = Client::builder()
            .homeserver_url(homeserver)
            .sled_store("/home/colin/mx-sanebot", None)?
            .build()
            .await?;
        println!("client built");
        client.login_username(&username, &password).initial_device_display_name("sanebot")
            .initial_device_display_name("sanebot")
            .send()
            .await?;

        println!("logged in as {username}");

        Ok(Runner { client })
    }

    async fn event_loop(&self) -> anyhow::Result<()> {
        // Now, we want our client to react to invites. Invites sent us stripped member
        // state events so we want to react to them. We add the event handler before
        // the sync, so this happens also for older messages. All rooms we've
        // already entered won't have stripped states anymore and thus won't fire
        self.client.add_event_handler(on_stripped_state_member);

        // An initial sync to set up state and so our bot doesn't respond to old
        // messages. If the `StateStore` finds saved state in the location given the
        // initial sync will be skipped in favor of loading state from the store
        let response = self.client.sync_once(SyncSettings::default()).await.unwrap();
        println!("sync'd");

        let settings = SyncSettings::default().token(response.next_batch);
        let mut sync_stream = Box::pin(
            self.client.sync_stream(settings)
            .await
        );
        while let Some(Ok(response)) = sync_stream.next().await {
            for (room_id, room) in &response.rooms.join {
                for e in &room.timeline.events {
                    if let Ok(event) = e.event.deserialize() {
                        self.handle_event(room_id, event).await;
                    }
                }
            }
        }

        // add our CommandBot to be notified of incoming messages, we do this after the
        // initial sync to avoid responding to messages before the bot was running.
        // self.client.add_event_handler(on_room_message);

        // // since we called `sync_once` before we entered our sync loop we must pass
        // // that sync token to `sync`
        // let settings = SyncSettings::default().token(response.next_batch);
        // // this keeps state from the server streaming in to CommandBot via the
        // // EventHandler trait
        // self.client.sync(settings).await?;

        Ok(())
    }

    async fn handle_event(&self, room_id: &RoomId, event: AnySyncTimelineEvent) {
        println!("Considering event {:?}", event);
        let sender = event.sender();
        if Some(sender) == self.client.user_id() {
            return; // don't react to self
        }

        match event {
            AnySyncTimelineEvent::MessageLike(ref msg_like) => match msg_like {
                AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(room_msg)) => match room_msg.content.msgtype {
                    MessageType::Text(ref text_msg) => {
                        let body = &text_msg.body;
                        println!("message from {sender}: {body}\n");
                        let resp = MessageHandler.on_msg(&body);
                        println!("response: {resp}");

                        let room = self.client.get_joined_room(room_id).unwrap();
                        let resp_content = RoomMessageEventContent::text_plain(&resp);
                        room.send(resp_content, None).await.unwrap();
                    },
                    ref other => {
                        println!("dropping RoomMessage event {other:?}");
                    },
                },
                other => {
                    println!("dropping MessageLike event {other:?}");
                },
            },
            AnySyncTimelineEvent::State(state) => {
                println!("dropping State event {state:?}");
            },
        }
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


#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let password = env::var("SANEBOT_PASSWORD").unwrap_or("password".into());
    let runner = Runner::login("https://uninsane.org", "sanebot", &*password).await?;
    let result = runner.event_loop().await;
    println!("exiting");
    result
}
