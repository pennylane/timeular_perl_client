package timeular;

use strict;
use warnings;
use warnings qw(all);

use LWP;
use JSON;
use REST::Client;
use HTTP::Cookies;
use Data::Dumper;

our $DEBUG = 0;

# Define simple debug print fuction
sub debug_print {
    if ($DEBUG) {
        my $message = "";
        my $level = 0;

        if (scalar(@_) >= 2) {
            ($message, $level) = @_;

            if ( $level <= $DEBUG ) {
                print "[DEBUG] $message \n";
            }
        } 
        else {
            if (scalar(@_) == 1) {
                print "[DEBUG] @_ \n";
            }
            else {
               return; 
           } 
        }
    }
}

1;
