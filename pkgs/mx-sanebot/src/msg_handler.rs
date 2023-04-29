use std::borrow::ToOwned;
use std::fmt;
use std::process;
use std::str;

use super::parsing;


mod tt {
    pub(super) use super::parsing::{
        Either,
        Lit,
        Then,
    };

    // grammar:
    // REQUEST = <!> (HELP | BT | BT-ADD)
    // HELP = <help>
    // BT = <bt>
    // BT-ADD = <bt-add> MAYBE_ARGS
    // MAYBE_ARGS = [SPACE [ARGS]]
    // ARGS = ARG MAYBE_ARGS
    // ARG = (not SPACE) [ARG]
    pub(super) type Request = Then<Bang, Either<Help, Bt>>;

    pub(super) type Bang = Lit<{ '!' as u8 }>;

    pub(super) type Help = Then<
        Lit<{ 'H' as u8 }>, Then<
        Lit<{ 'E' as u8 }>, Then<
        Lit<{ 'L' as u8 }>,
        Lit<{ 'P' as u8 }>,
    >>>;

    pub(super) type Bt = Then<
        Lit<{ 'B' as u8 }>,
        Lit<{ 'T' as u8 }>,
    >;
}

pub struct MessageHandler;

impl MessageHandler {
    /// parse any message directed to me, and return text to present to the user who messaged me.
    /// the message passed here may or may not be a "valid" request.
    /// if invalid, expect an error message or help message, still meant for the user.
    pub fn on_msg(&self, msg: &str) -> String {
        let req = self.parse_msg(msg).unwrap_or(Request::Help);
        let resp = req.evaluate();
        resp.to_string()
    }

    fn parse_msg(&self, msg: &str) -> Result<Request, ()> {
        let msg = msg.trim();
        match msg {
            "!help" => Ok(Request::Help),
            "!bt" => Ok(Request::Bt),
            _ => Err(())
        }
    }
}


enum Request {
    Help,
    Bt,
}

impl From<tt::Request> for Request {
    fn from(t: tt::Request) -> Self {
        match t {
            tt::Then(_bang, tt::Either::A(_help)) => Self::Help,
            tt::Then(_bang, tt::Either::B(_bt)) => Self::Bt,
        }
    }
}

impl Request {
    fn evaluate(self) -> Response {
        match self {
            Request::Help => Response::Help,
            Request::Bt => Response::Bt(
                process::Command::new("sane-bt-show")
                    .output()
                    .ok()
                    .and_then(|output|
                        str::from_utf8(&output.stdout).ok().map(ToOwned::to_owned)
                    ).unwrap_or_else(||
                        "failed to retrieve torrent status".to_owned())
            ),
        }
    }
}

enum Response {
    Help,
    Bt(String),
}

impl fmt::Display for Response {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Response::Help => {
                write!(f, "commands:\n")?;
                write!(f, "  !help => show this message\n")?;
                write!(f, "  !bt => show torrent statuses\n")?;
            },
            Response::Bt(stdout) => write!(f, "{}", stdout)?
        }
        Ok(())
    }
}
