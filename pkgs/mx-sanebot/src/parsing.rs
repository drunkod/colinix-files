/// for internal use.
/// parses only if the parser has no more bytes to yield.
struct Eof;

/// literal byte (character).
pub struct Lit<const BYTE: u8>;

/// the two-item sequence of A followed by B.
pub struct Then<A, B>(pub A, pub B);

/// if A parses, then A, else parse B.
pub enum Either<A, B> {
    A(A),
    B(B),
}

// case-insensitive u8 character.
// type ILit<const BYTE: u8> = Either<Lit<{ BYTE.to_ascii_lowercase() }>, Lit<{ BYTE.to_ascii_uppercase() }>>;


pub type PResult<P, C> = std::result::Result<(C, P), P>;
pub trait Parser: Sized {
    fn expect_byte(self, b: Option<u8>) -> PResult<Self, ()>;
    fn expect<C: Parse>(self) -> PResult<Self, C>;
    // {
    //     // support backtracking; i.e. don't modify `self` on failed parse
    //     match C::consume(self.clone()) {
    //          Ok(res) => res,
    //          Err(_) => self,
    //     }
    // }
    fn parse_all<C: Parse>(self) -> Result<C, ()> {
        match self.expect::<Then<C, Eof>>() {
            Ok((Then(c, _eof), _p)) => Ok(c),
            Err(_p) => Err(()),
        }
    }
}

pub trait Parse: Sized {
    fn consume<P: Parser>(p: P) -> PResult<P, Self>;
}

impl Parse for Eof {
    fn consume<P: Parser>(p: P) -> PResult<P, Self> {
        let (_, p) = p.expect_byte(None)?;
        Ok((Self, p))
    }
}

impl<const BYTE: u8> Parse for Lit<BYTE> {
    fn consume<P: Parser>(p: P) -> PResult<P, Self> {
        let (_, p) = p.expect_byte(Some(BYTE))?;
        Ok((Self, p))
    }
}

impl<A: Parse, B: Parse> Parse for Then<A, B> {
    fn consume<P: Parser>(p: P) -> PResult<P, Self> {
        let (a, p) = p.expect()?;
        let (b, p) = p.expect()?;
        Ok((Self(a, b), p))
    }
}

impl<A: Parse, B: Parse> Parse for Either<A, B> {
    fn consume<P: Parser>(p: P) -> PResult<P, Self> {
        let p = match p.expect() {
            Ok((a, p)) => { return Ok((Self::A(a), p)); },
            Err(p) => p,
        };
        let p = match p.expect() {
            Ok((b, p)) => { return Ok((Self::B(b), p)); },
            Err(p) => p,
        };
        Err(p)
    }
}

