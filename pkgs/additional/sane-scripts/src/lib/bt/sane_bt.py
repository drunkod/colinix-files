from __future__ import annotations

from argparse import ArgumentParser, Namespace
from dataclasses import dataclass

import logging
import os.path
import subprocess

logger = logging.getLogger(__name__)

@dataclass
class MediaMeta:
    title: str | None
    prefix: str | None
    author: str | None
    type_: "film" | "show" | "book" | "audiobook" | "vn"  # TODO: use enumeration
    freeleech: bool
    archive: bool

    @classmethod
    def add_arguments(self, parser: ArgumentParser) -> None:
        parser.add_argument("--prefix", help="additional path component before anything implied by the other options (but after the base media dir")
        parser.add_argument("--film", action="store_true")
        parser.add_argument("--show", help="ShowTitle")
        parser.add_argument("--book", help="BookTitle")
        parser.add_argument("--audiobook", help="AudiobookTitle")
        parser.add_argument("--vn", help="VisualNovelTitle  (for comics/manga)")
        parser.add_argument("--author", help="FirstnameLastname")
        parser.add_argument("--freeleech", action="store_true", help="not interested in the data, only in seeding")
        parser.add_argument("--archive", action="store_true", help="not interested in the data, except for archival")

    @classmethod
    def from_arguments(self, args: Namespace) -> Self:
        title = None
        type_ = None
        if args.film:
            type_ = "film"
        if args.show != None:
            type_ = "show"
            title = args.show
        if args.book != None:
            type_ = "book"
            title = args.book
        if args.audiobook != None:
            type_ = "audiobook"
            title = args.audiobook
        if args.vn != None:
            type_ = "vn"
            title = args.vn
        assert type_ is not None, "no torrent type specified!"
        assert not (args.freeleech and args.archive), "--freeleech and --archive are mutually exclusive"
        return MediaMeta(
            title=title,
            prefix=args.prefix,
            author=args.author,
            type_=type_,
            freeleech=args.freeleech,
            archive=args.archive,
        )

    @property
    def type_path(self) -> str:
        return dict(
            film="Videos/Film/",
            show="Videos/Shows/",
            book="Books/Books/",
            audiobook="Books/Audiobooks/",
            vn="Books/Visual/",
        )[self.type_]

    def fs_path(self, base: str="/var/lib/uninsane/media/") -> None:
        return os.path.join(
            base,
            self.prefix or "",
            "archive" if self.archive else "",
            "freeleech" if self.freeleech else "",
            self.type_path,
            self.author or "",
            self.title or "",
        )


def dry_check_output(args: list[str]) -> bytes:
    print("not invoking because dry run: " + ' '.join(args))
    return b""

class TransmissionApi:
    ENDPOINT="https://bt.uninsane.org/transmission/rpc"
    PASSFILE="/run/secrets/transmission_passwd"

    def __init__(self, check_output = subprocess.check_output):
        self.check_output = check_output

    @staticmethod
    def add_arguments(parser: ArgumentParser) -> None:
        parser.add_argument("--dry-run", action="store_true", help="only show what would be done; don't invoke transmission")

    @staticmethod
    def from_arguments(args: Namespace) -> Self:
        return TransmissionApi(check_output = dry_check_output if args.dry_run else subprocess.check_output)

    @property
    def auth(self) -> str:
        return open(self.PASSFILE, "r").read().strip()

    def add_torrent(self, meta: MediaMeta, torrent: str) -> None:
        self.call_transmission(
            description=f"saving to {meta.fs_path()}",
            args=[
                "--download-dir", meta.fs_path(),
                "--add", torrent,
            ]
        )

    def move_torrent(self, meta: MediaMeta, torrent: str) -> None:
        self.call_transmission(
            description=f"moving {torrent} to {meta.fs_path()}",
            args=[
                "--torrent", torrent,
                "--move", meta.fs_path()
            ]
        )

    def add_or_move_torrent(self, meta: MediaMeta, torrent: str) -> None:
        """
        if "torrent" represents a magnet or file URI, then add else
        else assume it's a transmission identifier and move it to the location specified by @p meta.
        """
        if torrent.isdigit():
            self.move_torrent(meta, torrent)
        else:
            self.add_torrent(meta, torrent)

    def rm_torrent(self, torrent: str | int) -> None:
        self.call_transmission(
            description=f"deleting {torrent}",
            args=[
                "--torrent", torrent,
                "--remove-and-delete"
            ]
        )

    def list_(self) -> str:
        return self.call_transmission([
            "--list"
        ])

    def info(self, torrent: str) -> str:
        return self.call_transmission([
            "--torrent", torrent,
            "--info"
        ])

    def call_transmission(self, args: list[str], description: str | None = None) -> str:
        if description is not None:
            logger.info(description)

        return self.check_output([
            "transmission-remote",
            self.ENDPOINT,
            "--auth", f"alex:{self.auth}",
        ] + args).decode("utf-8")
