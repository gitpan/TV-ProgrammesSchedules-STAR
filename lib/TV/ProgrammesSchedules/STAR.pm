package TV::ProgrammesSchedules::STAR;

use strict; use warnings;

use overload q("") => \&as_string, fallback => 1;

use Carp;
use Readonly;
use Data::Dumper;
use LWP::UserAgent;
use Time::localtime;
use HTTP::Request::Common;

=head1 NAME

TV::ProgrammesSchedules::STAR - Interface to STAR TV Programmes Schedules.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';
our $DEBUG   = 0;

Readonly my $BASE_URL => 'http://www.indya.com/uk/tvguide/tvguide.asp';
Readonly my $CHANNELS =>
{
    gold => 'STAR Gold',
    news => 'STAR News',
    one  => 'STAR One',
    plus => 'STAR Plus',
};

=head1 DESCRIPTION

STAR is a leading media and entertainment company in Asia. STAR broadcasts  over 60 television
services  in 13 languages to  more than 300 million viewers across 53 Asian countries. STAR TV
is the UK's leading provider for South Asian entertainment. STAR's bouquet of channels in  the
UK includes:

    +-----------+---------------------------------------------------------------------------+
    | Name      | Description                                                              |
    +-----------+---------------------------------------------------------------------------+
    | STAR Plus | UK's Most Watched Hindi Pay General Entertainment Channel.                |
    |           |                                                                           |
    | STAR One  | UK's lighter general entertainment channel reflecting contemporary India. |
    |           |                                                                           |
    | STAR Gold | The Widest Reaching Bollywood Movie Channel in the UK.                    |
    |           |                                                                           |
    | STAR News | Europe's First 24 Hours Hindi News Channel.                               |
    +-----------+---------------------------------------------------------------------------+

=head1 CONSTRUCTOR

The constructor optionally expects a reference to anonymous hash as input parameter.  Possible
keys  to the anonymous hash are ( yyyy, mm, dd ). The yyyy, mm and dd are optional. If missing
picks up the current year, month and day.

    use strict; use warnings;
    use TV::ProgrammesSchedules::STAR;

    my $star_today = TV::ProgrammesSchedules::STAR->new();
    my $star_on_2011_04_12 = TV::ProgrammesSchedules::STAR->new({ yyyy => 2011, mm => 4 dd => 12 });

=cut

sub new
{
    my $class = shift;
    my $param = shift;

    croak("ERROR: Input param has to be a ref to HASH.\n")
        if (defined($param) && (ref($param) ne 'HASH'));
    croak("ERROR: Invalid number of keys found in the input hash.\n")
        if (defined($param) && (scalar(keys %{$param}) != 3));

    $param->{_browser} = LWP::UserAgent->new();
    unless (defined($param) && defined($param->{yyyy}) && defined($param->{mm}) && defined($param->{dd}))
    {
        my $today = localtime;
        $param->{yyyy} = $today->year+1900;
        $param->{mm}   = $today->mon+1;
        $param->{dd}   = $today->mday;
    }

    _validate_date($param->{yyyy}, $param->{mm}, $param->{dd});
    bless $param, $class;
    return $param;
}

=head1 METHODS

=head2 get_listings()

Return the programmes listings for the given channel.Data would be in the form of reference to
a  list  containing  anonymous  hash  with keys time and title for each of the programmes. The
Possible values are listed below:

    +-----------+-------+
    | Channel   | Value |
    +-----------+-------+
    | STAR Plue | plus  |
    |           |       |
    | STAR One  | one   |
    |           |       |
    | STAR Gold | gold  |
    |           |       |
    | STAR News | news  |
    +-----------+-------+

    use strict; use warnings;
    use TV::ProgrammesSchedules::STAR;

    my $star = TV::ProgrammesSchedules::STAR->new();
    my $listings = $star->get_listings('news');

=cut

sub get_listings
{
    my $self    = shift;
    my $channel = shift;

    _validate_channel($channel);
    my ($browser, $ddDate);
    $browser = $self->{_browser};
    $ddDate  = sprintf("%02d_%02d_%04d", $self->{dd}, $self->{mm}, $self->{yyyy});
    if (exists($self->{$ddDate}->{$channel}))
    {
        print {*STDOUT} "Listing already cached previously...\n" if $DEBUG;
        return $self->{$ddDate}->{$channel};
    }

    my ($query, $response);
    $query    = [ ddChannelName => $CHANNELS->{$channel},
                  ddDate        => $ddDate
                ];
    print Dumper($query) if $DEBUG;
    $response = $browser->request(POST $BASE_URL, $query);
    croak("ERROR: Couldn't connect to [$BASE_URL].\n")
        unless $response->is_success;
    print {*STDOUT} "Fetch programmes listing for channel [$channel] date [$ddDate] using url [$BASE_URL]..\n"
        if $DEBUG;

    my ($contents, $listings, $program, $count);
    $contents = $response->content;
    foreach (split(/\n/,$contents))
    {
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        next if /^$/;
        my ($row, $line, $time, $title);
        if (/\<tr class\=black (.*)/)
        {
            $row = $1;
            $row =~ s/(.*?)\<\/td\>\<\/tr\>(.*)/$2/;
            while ($row =~ s/\<tr class(.*?)\<\/tr\>//)
            {
                $line = $1;

                $line =~ /(\d\d\:\d\d)/;
                $time = $1;

                $line =~ /\&nbsp\;(.*?)\<\/div\>/;
                $title = $1;

                $title =~ s/[^[:print:]+]//g;
                $title =~ s/^\s+|\s+$//g;

                push @$listings, { time => $time, title => $title };
            }
            $self->{listings} = $listings;
            return $listings;
        }
    }
    $self->{listings} = $listings;
    return $listings;
}

=head2 as_xml()

Returns listings in XML format. By default it returns todays lisitng for STAR News TV.

    use strict; use warnings;
    use TV::ProgrammesSchedules::STAR;

    my $star = TV::ProgrammesSchedules::STAR->new();
    my $listings = $star->get_listings('news');
    print $star->as_xml();

=cut

sub as_xml
{
    my $self = shift;
    my ($xml, $listings);

    $self->{listings} = $self->get_listings('news')
        unless defined($self->{listings});

    $xml = qq {<?xml version="1.0" encoding="UTF-8"?>\n};
    $xml.= qq {<programmes>\n};
    foreach (@{$self->{listings}})
    {
        $xml .= qq {\t<programme>\n};
        $xml .= qq {\t\t<time> $_->{time} </time>\n};
        $xml .= qq {\t\t<title> $_->{title} </title>\n};
        $xml .= qq {\t</programme>\n};
    }
    $xml.= qq {</programmes>};
    return $xml;
}

=head2 as_string()

Returns listings in a human readable format. By default it returns STAR News lisitng.

    use strict; use warnings;
    use TV::ProgrammesSchedules::STAR;

    my $star     = TV::ProgrammesSchedules::STAR->new();
    my $listings = $star->get_listings('news');

    print $star->as_string();

    # or even simply
    print $star;

=cut

sub as_string
{
    my $self = shift;
    my ($listings);

    $self->{listings} = $self->get_listings('news')
        unless defined($self->{listings});

    foreach (@{$self->{listings}})
    {
        $listings .= sprintf(" Time: %s\n", $_->{time});
        $listings .= sprintf("Title: %s\n", $_->{title});
        $listings .= "-------------------\n";
    }
    return $listings;
}

sub _validate_channel
{
    my $channel = shift;

    croak("ERROR: Channel undefined.\n")
        unless defined $channel;

    croak("ERROR: Invalid channel [$channel].\n")
        unless exists($CHANNELS->{lc($channel)});
}

sub _validate_date
{
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    croak("ERROR: Invalid year [$yyyy].\n")
        unless (defined($yyyy) && ($yyyy =~ /^\d{4}$/) && ($yyyy > 0));
    croak("ERROR: Invalid month [$mm].\n")
        unless (defined($mm) && ($mm =~ /^\d{1,2}$/) && $mm >= 1 && $mm <= 12);
    croak("ERROR: Invalid day [$dd].\n")
        unless (defined($dd) && ($dd =~ /^\d{1,2}$/) && $dd >= 1 && $dd <= 31);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs/feature requests to  C<bug-tv-programmesschedules-star at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TV-ProgrammesSchedules-STAR>.
I'll be notified, and then you'll automatically be notified of  progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TV::ProgrammesSchedules::STAR

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TV-ProgrammesSchedules-STAR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TV-ProgrammesSchedules-STAR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TV-ProgrammesSchedules-STAR>

=item * Search CPAN

L<http://search.cpan.org/dist/TV-ProgrammesSchedules-STAR/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This program is free software;  you  can redistribute it and / or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of TV::ProgrammesSchedules::STAR