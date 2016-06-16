#!perl -T

use strict;
use warnings;
use Test::More tests => 13;

use lib 't';
use Util;

use File::Copy ();
use File::Temp;

use File::Next;

# use Test::Differences;
# eq_or_diff \@got, [qw( a b c )], "testing arrays";

my @expected = qw(
    t/00-load.t
    t/api.t
    t/basic.t
    t/dirs.t
    t/dot.t
    t/everything.t
    t/follow.t
    t/from_file.t
    t/methods.t
    t/named-pipe.t
    t/parms.t
    t/pod-coverage.t
    t/pod.t
    t/sort.t
    t/swamp/perl-test.t
    t/zero.t
);


FROM_FILESYSTEM_FILE: {
    my $iter = File::Next::from_file( 't/filelist.txt' );
    isa_ok( $iter, 'CODE' );

    my @actual = slurp( $iter );
    sets_match( \@actual, \@expected, 'FROM_FILESYSTEM_FILE' );
}

FROM_NUL_FILE: {
    my $iter = File::Next::from_file( { nul_separated => 1 }, 't/filelist-nul.txt' );
    isa_ok( $iter, 'CODE' );

    my @actual = slurp( $iter );
    sets_match( \@actual, \@expected, 'FROM_NUL_FILE' );
}

FROM_UNSPECIFIED_FILE: {
    my $iter;
    my $rc = eval {
        $iter = File::Next::from_file();
    };
    like( $@, qr/Must pass a filename to from_file/, 'Proper error message' );
    ok( !defined($iter), 'Iterator should be null' );
    ok( !defined($rc), 'Eval should fail' );
}

FROM_MISSING_FILE: {
    my $iter;
    my $rc = eval {
        $iter = File::Next::from_file( 'flargle-bargle.txt' );
    };

    like( $@, qr/\QUnable to open flargle-bargle.txt/, 'Proper error message' );
    ok( !defined($iter), 'Iterator should be null' );
    ok( !defined($rc), 'Eval should fail' );
}

FROM_OK_FILE_BUT_MISSING: {
    my $warn_called;
    local $SIG{__WARN__} = sub { $warn_called = 1 };

    my $tempfile = File::Temp->new;
    File::Copy::copy('t/filelist.txt', $tempfile);
    print {$tempfile} "t/non-existent-file.txt\n";
    $tempfile->close;

    my $iter = File::Next::from_file( $tempfile->filename );
    isa_ok( $iter, 'CODE' );

    my @actual = slurp( $iter );
    sets_match( \@actual, \@expected, 'FROM_FILESYSTEM_FILE' );

    ok($warn_called, 'CORE::warn() should be called if a warning occurs and no warning_handler is set');
}
