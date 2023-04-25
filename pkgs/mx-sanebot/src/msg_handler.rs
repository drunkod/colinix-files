use std::fmt;

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
        if msg == "!help" {
            Ok(Request::Help)
        } else {
            Err(())
        }
    }
}


enum Request {
    Help,
}

impl Request {
    fn evaluate(self) -> Response {
        match self {
            Request::Help => Response::About,
        }
    }
}

enum Response {
    About,
}

impl fmt::Display for Response {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "commands:\n")?;
        write!(f, "  !help => show this message\n")?;
        Ok(())
    }
}
