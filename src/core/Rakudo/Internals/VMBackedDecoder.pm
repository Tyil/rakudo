my class Supply { ... }

my class Rakudo::Internals::VMBackedDecoder is repr('Decoder') {
    method new(str $encoding, :$translate-nl) {
        nqp::decoderconfigure(nqp::create(self), $encoding,
            $translate-nl ?? nqp::hash('translate_newlines', 1) !! nqp::null())
    }

    method add-bytes(Blob:D $bytes --> Nil) {
        nqp::decoderaddbytes(self, nqp::decont($bytes));
    }

    method consume-available-chars(--> Str:D) {
        nqp::decodertakeavailablechars(self)
    }

    method consume-all-chars(--> Str:D) {
        nqp::decodertakeallchars(self)
    }

    method consume-exactly-chars(int $chars --> Str) {
        my str $result = nqp::decodertakechars(self, $chars);
        nqp::isnull_s($result) ?? Str !! $result
    }

    method set-line-separators(@seps --> Nil) {
        my $sep-strs := nqp::list_s();
        nqp::push_s($sep-strs, .Str) for @seps;
        nqp::decodersetlineseps(self, $sep-strs);
    }

    method consume-line-chars(Bool:D :$chomp = False, Bool:D :$eof = False --> Str) {
        my str $line = nqp::decodertakeline(self, $chomp, $eof);
        nqp::isnull_s($line) ?? Str !! $line
    }
}

augment class Rakudo::Internals {
    method BYTE_SUPPLY_DECODER(Supply:D $bin-supply, Str:D $enc, :$translate-nl) {
        my $norm-enc = self.NORMALIZE_ENCODING($enc);
        supply {
            my $decoder = Rakudo::Internals::VMBackedDecoder.new($norm-enc, :$translate-nl);
            whenever $bin-supply {
                $decoder.add-bytes($_);
                my $available = $decoder.consume-available-chars();
                emit $available if $available ne '';
                LAST {
                    # XXX The `with` is required due to a bug where the
                    # LAST phaser is not properly scoped if we don't get
                    # any bytes. Since that means there's nothing to emit
                    # anyway, we'll not worry about this case for now.
                    #
                    # --- or at least that was the the idea before we fixed
                    # that bug: https://irclog.perlgeek.de/perl6/2016-12-07#i_13698178
                    # and tried removing the `with` in 58cdfd8, but then the error
                    # `No such method 'consume-all-chars' for invocant of type 'Any`
                    # started popping up on Proc::Async tests, so...
                    # there may be some other bug affecting this?
                    with $decoder {
                        my $rest = .consume-all-chars();
                        emit $rest if $rest ne '';
                    }
                }
            }
        }
    }
}
