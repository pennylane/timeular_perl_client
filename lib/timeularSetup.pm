package timeularSetup;

use strict;
use warnings;
use warnings qw(all);

use LWP;
use JSON;
use REST::Client;
use HTTP::Cookies;
use Data::Dumper;

#our $proxy = '';

our $apikey      = "xxx";
our $apisecret   = "yyy";

our $token = "";
our $serial = "";
our $headers = { "Content-type" => "application/json", "Accept" => "application/json;charset=UTF-8" };

my $cookiejar = HTTP::Cookies->new();
my $useragent = LWP::UserAgent->new();
$useragent->cookie_jar( $cookiejar );
$useragent->agent('Mozilla/5.0');

our $client = REST::Client->new( { useragent => $useragent } );
$client->setHost('https://api.timeular.com/api/v2');
$client->getUseragent()->proxy(['http'], $proxy);
$client->getUseragent()->proxy(['https'], $proxy);
$client->setFollow(1);

1;
