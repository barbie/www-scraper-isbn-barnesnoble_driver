#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 20;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'BarnesNoble';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'             ],
        [ 'is',     'isbn10',       '0571239560'                ],
        [ 'is',     'isbn13',       '9780571239566'             ],
        [ 'is',     'ean13',        '9780571239566'             ],
        [ 'like',   'title',        qr!Touching from a Distance!],
        [ 'like',   'author',       qr!Curtis!                  ],
        [ 'is',     'publisher',    'Faber and Faber'           ],
        [ 'is',     'pubdate',      'October 2007'              ],
        [ 'is',     'binding',      'Paperback'                 ],
        [ 'is',     'pages',        240                         ],
        [ 'is',     'width',        undef                       ],
        [ 'is',     'height',       undef                       ],
        [ 'is',     'weight',       undef                       ],
        [ 'is',     'image_link',   'http://img2.imagesbn.com/images/27350000/27350367.JPG' ],
        [ 'is',     'thumb_link',   'http://img2.imagesbn.com/images/27350000/27350367.JPG' ],
        [ 'like',   'description',  qr|Joy Division|            ],
        [ 'like',   'book_link',    qr|search.barnesandnoble.com/Touching-from-a-Distance/Curtis/e/9780571239566| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
    skip "Can't see a network connection", $tests   if(pingtest($CHECK_DOMAIN));

    $scraper->drivers($DRIVER);

    my $record;

# Code below removed as some testers appear to have badly configured
# Business::ISBN objects, as used by WWW::Scraper::ISBN :(
#
#    # this ISBN doesn't exist
#    my $isbn = "99999999990";
#    eval { $record = $scraper->search($isbn); };
#    if($@) {
#        like($@,qr/Invalid ISBN specified/);
#    }
#    elsif($record->found) {
#        ok(0,'Unexpectedly found a non-existent book');
#    } else {
#       like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
#    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable [$error]", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/ || !$record->found);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag();
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
