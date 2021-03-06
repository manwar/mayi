use strict;
use warnings;
use FindBin qw( $Bin $RealBin );
use Tie::File;

exit 0 unless $ENV{dan} || $ENV{box} || $ENV{def};

sub mydanpath
{
    if ( my $path = $ENV{mydan} )
    {
        my @p = split /\//, $path;
        die "The directory name must be mydan. example: /tmp/abc/mydan\n"
            unless $p[-1] eq 'mydan';
        return $path;
    }
    for ( $RealBin, $ENV{PERL_PATH}, $^X )
    {
        next unless $_;
        my @p = split /\//, $_;
        while ( @p ) { $p[-1] eq 'mydan' ? last : pop @p; }
        return join( '/', @p ) if @p;
    }
    return '/opt/mydan';
}

my $mydan = mydanpath();
system "mkdir -p '$mydan'" unless -e $mydan;

my $perl = $ENV{PERL_PATH} || $^X;
my $cpan = $perl;$cpan =~ s/perl$/cpan/;
$cpan = $ENV{cpan} unless -f $cpan;
die "no find cpan" unless -f $cpan;

sub mysystem
{
    my $cmd = shift;
    die "$cmd fail:$!" if system $cmd;
}

sub repl
{
    my ( $type, %reg ) = @_;
    for my $file ( `find $type -type f` )
    {
        chomp $file;
        tie my ( @file ), 'Tie::File', $file;
    
        if( @file )
        {
            if( %reg )
            {
                while( my ( $k, $v ) = each %reg )
                {
                    map{ $_ =~ s/$k/$v/g }@file;
                }
            }
            else
            {
                $file[0] = "#!$perl$1" if $file[0] =~ /#![^#]*perl(.*$)/o;
            }
        }

        warn "$file\n";
        untie @file;
    }
}

sub insl
{
   
    print '#' x 30, " check module ", '#' x 30, "\n";
   
    map{
        $_ =~ s/'//g;
        if( system "$perl -e \"use $_\" >/dev/null 2>&1" )
        {
            print "install $_\n";
            mysystem( "$cpan install $_" );
        }
        else { print "$_=> ok.\n"; }
        print '-' x 74, "\n";
    }@_;
    
}


if( $ENV{dan} )
{
    mysystem "rsync -a dan/ dan.i/";
    repl( 'dan.i' );
    mysystem "rsync -a dan.i/ '$mydan/dan/'";

    my %m;
    tie my ( @file ), 'Tie::File', 'Makefile.PL';
    map{ $m{$1} = 1 if $_ =~ /\s+'?([:\w]+)'? => [\d\.]+/ }@file;
    untie @file;

    insl( keys %m );   
}

if( $ENV{box} )
{

    mysystem "rsync -a box/ box.i/";
    mysystem "rsync -a dan/node/ box.i/node/";
    map { mysystem "rsync -a dan/tools/$_ box.i/tools/" } qw(range mcmd mssh expect vssh go mrsync rsync alias unalias sync config whois gateway git );
    

    my @sed = (
        'box.i/tools/vssh' => [ 'logname', 'id -un' ],
        'box.i/tools/vssh' => [ 'MYDan::VSSH::Execute::dan=1', 'MYDan::VSSH::Execute::dan=0' ],
        'box.i/tools/mrsync' => [ 'MYDan::Agent::Mrsync', 'MYDan::Util::Mrsync' ],
    );
    while( my ( $f, $s ) = splice @sed, 0, 2  )
    {
        tie my ( @file ), 'Tie::File', $f;
        map{ s/$s->[0]/$s->[1]/g }@file;
        untie @file;
    }

    repl( 'box.i' );
    mysystem "rsync -a box.i/ '$mydan/box/'";

    unless( $ENV{dan} )
    {
         my %m;
         tie my ( @file ), 'Tie::File', 'Makefile.PL';
         map{ $m{$1} = 1 if $_ =~ /\s+'?([:\w]+)'? => [\d\.]+,\s*#box/ }@file;
         untie @file;

         insl( keys %m );
    }
}

if( $ENV{dan} || $ENV{box} || $ENV{bin} )
{
    mysystem "rsync -a bin/ bin.i/";
    repl( 'bin.i' );
    mysystem( "ln -fsn mydan bin.i/$ENV{nickname}" )
        if $ENV{nickname} && $ENV{nickname} =~ /^[a-z0-9]+$/;
    mysystem "rsync -a bin.i/ '$mydan/bin/'";
}

if( $ENV{def} )
{
    mysystem( "rsync -av def/ def.i/" );
    repl( 'def.i', MYDanROOT => $mydan );
    mysystem( "rsync -av def.i/ ../" );
}

exit 0;
