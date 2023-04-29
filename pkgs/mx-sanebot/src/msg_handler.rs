use std::borrow::ToOwned;
use std::fmt;
use std::process;
use std::str;

use super::parsing::{self, Parser};


mod tt {
    pub(super) use super::parsing::{
        Either,
        Lit,
        Maybe,
        Nul,
        OneOrMore,
        Then,
    };
    use crate::{ilit, lit};

    // grammar:
    // REQUEST = <!> (HELP | BT-REQ)
    //
    // HELP = <help>
    // BT-REQ = <bt> [(BT-SEARCH | BT-ADD)]
    //
    // BT-SEARCH = <search> ARGS
    // BT-ADD = <add> ARGS
    //
    // MAYBE_ARGS = [SPACE [ARGS]]
    // ARGS = ARG MAYBE_ARGS
    // ARG = NOT-SPACE [ARG]
    //
    // NOT-SPACE = (ALPHA | NUM | SPECIAL)
    pub(super) type Request = Then<Bang, Either<Help, BtReq>>;

    pub(super) type Bang = Lit<{ '!' as u8 }>;
    pub(super) type Space = Lit<{ ' ' as u8 }>;
    pub(super) type Alpha = Either<
        ilit!('A'), Either<
        ilit!('B'), Either<
        ilit!('C'), Either<
        ilit!('D'), Either<
        ilit!('E'), Either<
        ilit!('F'), Either<
        ilit!('G'), Either<
        ilit!('H'), Either<
        ilit!('I'), Either<
        ilit!('J'), Either<
        ilit!('K'), Either<
        ilit!('L'), Either<
        ilit!('M'), Either<
        ilit!('N'), Either<
        ilit!('O'), Either<
        ilit!('P'), Either<
        ilit!('Q'), Either<
        ilit!('R'), Either<
        ilit!('S'), Either<
        ilit!('T'), Either<
        ilit!('U'), Either<
        ilit!('V'), Either<
        ilit!('W'), Either<
        ilit!('X'), Either<
        ilit!('Y'),
        ilit!('Z'),
    >>>>>>>>>>>>>>>>>>>>>>>>>;
    pub(super) type Dig = Either<
        lit!('0'), Either<
        lit!('1'), Either<
        lit!('2'), Either<
        lit!('3'), Either<
        lit!('4'), Either<
        lit!('5'), Either<
        lit!('6'), Either<
        lit!('7'), Either<
        lit!('8'),
        lit!('9'),
    >>>>>>>>>;
    pub(super) type Symbol = Either<
        Bang, Either<
        lit!('@'), Either<
        lit!('#'), Either<
        lit!('$'), Either<
        lit!('%'), Either<
        lit!('^'), Either<
        lit!('&'), Either<
        lit!('*'), Either<
        lit!('('), Either<
        lit!(')'), Either<
        lit!('-'), Either<
        lit!('_'), Either<
        lit!('+'), Either<
        lit!('='), Either<
        lit!('['), Either<
        lit!('{'), Either<
        lit!(']'), Either<
        lit!('}'), Either<
        lit!('\\'), Either<
        lit!('|'), Either<
        lit!(';'), Either<
        lit!(':'), Either<
        lit!('\''), Either<
        lit!('"'), Either<
        lit!(','), Either<
        lit!('<'), Either<
        lit!('.'), Either<
        lit!('>'), Either<
        lit!('/'), Either<
        lit!('?'), Either<
        lit!('`'),
        lit!('~'),
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>;
    // pub(super) type Whitespace = Then<Space, Maybe<Box<Whitespace>>>;
    pub(super) type Whitespace = OneOrMore<Space>;

    pub(super) type Help = Then<
        ilit!('H'), Then<
        ilit!('E'), Then<
        ilit!('L'),
        ilit!('P'),
    >>>;

    pub(super) type BtReq = Then<Bt, Maybe<Then<Whitespace, BtSearch>>>;

    pub(super) type Bt = Then<
        ilit!('B'),
        ilit!('T'),
    >;

    pub(super) type BtSearch = Then<Search, OneOrMore<SpacedArg>>;

    pub(super) type Search = Then<
        ilit!('S'), Then<
        ilit!('E'), Then<
        ilit!('A'), Then<
        ilit!('R'), Then<
        ilit!('C'),
        ilit!('H'),
    >>>>>;

    pub(super) type SpacedArg = Then<Whitespace, Arg>;
    pub(super) type Arg = OneOrMore<Either<
        Alpha, Either<
        Dig,
        Symbol
    >>>;
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
        match msg.as_bytes().parse_all::<tt::Request>() {
            Ok(req) => Ok(req.into()),
            Err(_) => Err(()),
        }
    }
}


enum Request {
    Help,
    Bt,
    BtSearch(String),
}

impl From<tt::Request> for Request {
    fn from(t: tt::Request) -> Self {
        match t {
            tt::Then(_bang, tt::Either::A(_help)) => Self::Help,
            tt::Then(_bang, tt::Either::B(bt_req)) => match bt_req {
                tt::Then(_bt, tt::Either::A(tt::Then(_ws, bt_search))) => {
                    let tt::Then(_, spaced_args) = bt_search;
                    Self::BtSearch(spaced_args.to_string())
                },
                tt::Then(_bt, tt::Either::B(tt::Nul)) => Self::Bt,
            }
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
            Request::BtSearch(phrase) => Response::BtSearch(
                process::Command::new("sane-bt-search")
                    .args([&*phrase])
                    .output()
                    .ok()
                    .and_then(|output|
                        str::from_utf8(&output.stdout).ok().map(ToOwned::to_owned)
                    ).unwrap_or_else(||
                        "failed to complete torrent search".to_owned())
            ),
        }
    }
}

enum Response {
    Help,
    Bt(String),
    BtSearch(String),
}

impl fmt::Display for Response {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Response::Help => {
                write!(f, "commands:\n")?;
                write!(f, "  !help => show this message\n")?;
                write!(f, "  !bt => show torrent statuses\n")?;
                write!(f, "  !bt search <phrase> => search for torrents\n")?;
            },
            Response::Bt(stdout) => write!(f, "{}", stdout)?,
            Response::BtSearch(stdout) => write!(f, "{}", stdout)?,
        }
        Ok(())
    }
}
