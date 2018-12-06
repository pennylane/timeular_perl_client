package timeularREST;

use strict;
use warnings;
use warnings qw(all);

use LWP;
use JSON;
use REST::Client;
use HTTP::Cookies;
use Data::Dumper;
use Text::Table;
use Sort::Key;
use Try::Tiny;
use Time::Format;
use Date::Manip;

use timeular;
use timeularSetup;

our $client      = $timeularSetup::client;
our $headers     = $timeularSetup::headers;
our $apikey      = $timeularSetup::apikey;
our $apisecret   = $timeularSetup::apisecret;
our $token       = $timeularSetup::token;
our $serial      = $timeularSetup::serial;

# API sign in 
# Requires API key and API secret, returns API token for authorization
sub signin {

    if ($token eq '') {

        timeular::debug_print("Signing in ...");

        $client->POST('/developer/sign-in', '{ "apiKey": "'.$apikey.'", "apiSecret": "'.$apisecret.'" }', $headers);
        timeular::debug_print('POST "'.$client->getHost().'/developer/sign-in"', 3);

        my $response_code = $client->responseCode();
        my $response_content = $client->responseContent();
        my $response_json = JSON->new->decode($response_content);
        timeular::debug_print("Response code: ".$response_code, 3);
        timeular::debug_print("Response content: ".$response_content, 3);

        if ($response_code != 200) {
            die "[ERROR] $response_content \n";
        }

        $token = $response_json->{'token'};
        timeular::debug_print("Token: ".$response_json->{'token'});
        if (length($token) > 0) {
            timeular::debug_print('Sign in successful!', 1);
        }

    }

    $headers->{'Authorization'} = 'Bearer '.$token;
}

# Basic GET request
# Sets URL and authorization header, gets path as argument
# Automatically calls sign in routine if token is empty
sub get_request {

    my $path = '';
    if (scalar(@_) == 1) {
        ($path) = @_;
    } else {
        die "[ERROR] Argument error in get_request \n"
    }   
        
    timeularREST::signin();

    $client->GET($path, $headers);
    timeular::debug_print('GET "'.$client->getHost().$path, 2);
    timeular::debug_print("Request headers: ".join( ',', map { "$_:$headers->{$_}" } keys %$headers ), 3);

    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();
    my $response_json_decode = JSON->new->decode($response_content);
    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response content: ".$response_content, 3);

    return $response_json_decode;
}

# More complex GET request 
# Sets URL and authorization header, gets path and timestamps as argument
# Automatically calls sign in routine if token is empty
sub get_request_complex {

    my $path = '';
    my $request_path = '';
    my $stopped_after = '1970-01-01T23:59:59.999';
    my $started_before = '1970-01-01T00:00:00.000';
    my %query = ();
        
    timeularREST::signin();
    
    if (scalar(@_) >= 3) {
        ($path, $stopped_after, $started_before, %query) = @_; 
    } else {
        die "[ERROR] Argument error in delete_request \n"
    }   
    timeular::debug_print("Getting entries between $stopped_after and $started_before");

    $request_path = "$path/$stopped_after/$started_before".$client->buildQuery(%query);
    timeular::debug_print("Request headers: ".join( ',', map { "$_:$headers->{$_}" } keys %$headers ), 3);
    timeular::debug_print("Request path: ".$request_path, 3);

    $client->GET($request_path, $headers);
    timeular::debug_print('GET "'.$client->getHost().@_, 2);
    
    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();

    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response content: ".$response_content, 3);

    my $response_json_decode = ''; 
    try {
        $response_json_decode = JSON->new->decode($response_content);
        return $response_json_decode;
    } catch {
        return $response_content;
    };
    
}

### ACTIVITIES ###

# Get defined activities
sub get_activities {

    timeular::debug_print("Fetching activities ...", 2);

    my $response = timeularREST::get_request('/activities');
    my @activities = @{$response->{'activities'}};

    if (scalar(@activities) >= 1) {

        my $table = Text::Table->new(
            "Id\n--", 
            "Activity\n--------", 
            "Side\n-----",
            "Color\n-----",
        );

        foreach (@activities) {
            $table->add(
                $_->{'id'},
                $_->{'name'}, 
                $_->{'deviceSide'}, 
                $_->{'color'},
            );
        }
        print $table;
        print "\n";

        return @activities;
    } else {
        die('[ERROR] Argument error in get_activities');
    }

}

### DEVICES ### 

# Get device serial
sub get_device {

    timeular::debug_print("Fetching device ...", 2);

    my $response = timeularREST::get_request('/devices');
    
    if ($response->{'devices'}[0]) {
        $serial = $response->{'devices'}[0]->{'serial'};
        print("ZEI device:\n-----------\n");
        print("Name: ".$response->{'devices'}[0]->{'name'}."\n");
        print("Serial: ".$serial."\n");
        print("Active: ".$response->{'devices'}[0]->{'active'}."\n");
        print("Disabled: ".$response->{'devices'}[0]->{'disabled'}."\n");
        print "\n";
        
        return $serial;
    } else {
        timeular::debug_print('No device found!');
    }
}

### TRACKING & ENTRIES ###

# Get current tracking status
sub get_tracking {

    timeular::debug_print("Fetching tracking ...", 2);

    my $response = timeularREST::get_request('/tracking');
    my $current = $response->{'currentTracking'};

    if (defined $current) {
        print("Current activity: ".$current->{'activity'}->{'name'}."\n");
        print("    ID: ".$current->{'activity'}->{'id'}."\n");
        print("    Started at: ".$current->{'startedAt'}."\n");
        if ( $current->{'note'}->{'text'} ) {
            print("    Note: ".$current->{'note'}->{'text'}."\n" );
        }
        print "\n";
        
        return $current;
    } else {
        print("ZEI currently not tracking.\n");
    }

}

# Get time entries between stopped_after and started_before
sub get_time_entries {

    my $stopped_after = '';
    my $started_before = '';
    ($stopped_after, $started_before) = @_;

    my $response = timeularREST::get_request_complex('/time-entries', $stopped_after, $started_before);

    my @activities = @{$response->{'timeEntries'}};

    if (scalar(@activities) >= 1) {

        my $table = Text::Table->new(
            "Entry ID\n--------",
            "Activity\n--------", 
            "Duration\n--------",
            "Started at\n----------",
            "Stopped at\n----------",
            "Text\n----", 
            "Tags\n----", 
            "Mentions\n--------", 
        );

        @activities = Sort::Key::ikeysort { $_->{'id'} } @activities;

        foreach (@activities) {

            my @tags = ();
            foreach($_->{'note'}->{'tags'}) {
                foreach my $tag_ref ($_) {
                    foreach (@$tag_ref) {
                        push @tags, $_->{'key'};
                    }
                }
            }

            my @mentions = ();
            foreach($_->{'note'}->{'mentions'}) {
                foreach my $mention_ref ($_) {
                    foreach (@$mention_ref) {
                        push @mentions, $_->{'key'};
                    }
                }
            }
            
            # remove tags and mentions from text output
            my $text = '';
            if ($_->{'note'}->{'text'}) {
                $text = $_->{'note'}->{'text'};
                $text =~ s/[#@].*//g;
            }

            # calculate time diff for duration output 
            my @stoptime    = split( ':', $time{ 'yyyy:mm:dd:hh:mm:ss', Date::Manip::ParseDate($_->{'duration'}->{'stoppedAt'}) } );
            my @starttime   = split( ':', $time{ 'yyyy:mm:dd:hh:mm:ss', Date::Manip::ParseDate($_->{'duration'}->{'startedAt'}) } );
            my $diff = sprintf ( "%02d:%02d:%02d", (($stoptime[3] - $starttime[3])%24), (($stoptime[4] - $starttime[4])%60), (($stoptime[5] - $starttime[5])%60) );
            
            $table->add(
                $_->{'id'}, 
                $_->{'activity'}->{'name'}, 
                $diff,
                $time{'yyyy-mm-dd hh:mm:ss', Date::Manip::ParseDate($_->{'duration'}->{'startedAt'})},
                $time{'yyyy-mm-dd hh:mm:ss', Date::Manip::ParseDate($_->{'duration'}->{'stoppedAt'})},
                $text,
                join(',', @tags),
                join(',',@mentions),
            );
        }
        print $table;
        print "\n";

        return @activities;
    }

}

# Get time entry by id
sub get_entry {
    
    timeular::debug_print("Fetching entry @_ ...", 2);

    my $response = timeularREST::get_request("/time-entries/@_");
    my $entry = $response;

    if ($entry) {
        print("Entry $entry->{'id'}\n--------------\n");
        print("Name: ".$entry->{'activity'}->{'name'}."\n");
        print("Started at: ".$entry->{'duration'}->{'startedAt'}."\n");
        print("Stopped at: ".$entry->{'duration'}->{'stoppedAt'}."\n");
        if ( $entry->{'note'}->{'text'} ) {
            print("Note: \n".$entry->{'note'}->{'text'}."\n" );
        }
        print "\n";

        return $entry;
    } else {
        print("[ERROR] Entry @_ not found.\n");
    }

}

### TAGS & MENTIONS ###

# Get tags and mentions
sub get_tags {

    timeular::debug_print("Fetching tags and mentions ...", 2);

    my $response = timeularREST::get_request('/tags-and-mentions');
    my @tags = ();
    my @mentions = ();

    if ($response) {

        foreach($response->{'tags'}) {
            foreach my $tag_ref ($_) {
                foreach (@$tag_ref) {
                    push @tags, $_->{'key'};
                }
            }
        }
        
        foreach($response->{'mentions'}) {
            foreach my $mention_ref ($_) {
                foreach (@$mention_ref) {
                    push @mentions, $_->{'key'};
                }
            }
        }

        my $len_table = scalar(@tags) >= scalar(@mentions) ? scalar(@tags) : scalar(@mentions);
        my $table = Text::Table->new(
            "Tags: \n------",
            "Mentions: \n----------",
        );
        for(my $i = 0; $i < $len_table; $i++) {
            $table->add($tags[$i], $mentions[$i]);
        }
        print $table;
        print "\n";
    }

    timeular::debug_print("Tags:\n".join(',', @tags), 3);
    timeular::debug_print("Mentions:\n".join(',', @mentions), 3);
    return (\@tags, \@mentions);
}

sub get_tag_index {

    my $index = 0;
    my $response = '';
    my $id = '';
    
    ($id) = @_;
    if ($id) { 

        $response = timeularREST::get_request("/time-entries/@_");

        foreach($response->{'note'}->{'tags'}) {
            foreach my $tag_ref ($_) {
                foreach (@$tag_ref) {
                    if ($_->{'indices'}[1] > $index) {
                        $index = $_->{'indices'}[1];
                    }
                }
            }
        }

    } else {

        $response = timeularREST::get_request('/tracking');

        foreach($response->{'currentTracking'}->{'note'}->{'tags'}) {
            foreach my $tag_ref ($_) {
                foreach (@$tag_ref) {
                    if ($_->{'indices'}[1] > $index) {
                        $index = $_->{'indices'}[1];
                    }
                }
            }
        }
    }

    timeular::debug_print("Maximum index is $index", 2);
    return $index;

}

sub get_mention_index {

    my $index = 0;
    my $response = '';
    my $id = '';
    
    ($id) = @_;
    if ($id) { 

        $response = timeularREST::get_request("/time-entries/@_");

        foreach($response->{'note'}->{'mentions'}) {
            foreach my $mention_ref ($_) {
                foreach (@$mention_ref) {
                    if ($_->{'indices'}[1] > $index) {
                        $index = $_->{'indices'}[1];
                    }
                }
            }
        }

    } else {

        $response = timeularREST::get_request('/tracking');

        foreach($response->{'currentTracking'}->{'note'}->{'mentions'}) {
            foreach my $mention_ref ($_) {
                foreach (@$mention_ref) {
                    if ($_->{'indices'}[1] > $index) {
                        $index = $_->{'indices'}[1];
                    }
                }
            }
        }
    }

    timeular::debug_print("Maximum index is $index", 2);
    return $index;

}

sub get_entry_tags_and_mentions {

    my $index = 0;
    my $response = '';
    my @tags = ();
    my @mentions = ();

    my $id = '';
    
    ($id) = @_;
    if ($id) { 

        $response = timeularREST::get_request("/time-entries/@_");

        foreach($response->{'note'}->{'tags'}) {
            foreach my $tag_ref ($_) {
                foreach (@$tag_ref) {
                    push @tags, $_->{'key'};
                }
            }
        }

        foreach($response->{'note'}->{'mentions'}) {
            foreach my $mention_ref ($_) {
                foreach (@$mention_ref) {
                    print $_->{'indices'}[1]."\n";
                    push @mentions, $_->{'key'};
                }
            }
        }

    } else {

        $response = timeularREST::get_request('/tracking');

        foreach($response->{'currentTracking'}->{'note'}->{'tags'}) {
            foreach my $tag_ref ($_) {
                foreach (@$tag_ref) {
                    push @tags, $_->{'key'};
                }
            }
        }

        foreach($response->{'currentTracking'}->{'note'}->{'mentions'}) {
            foreach my $mention_ref ($_) {
                foreach (@$mention_ref) {
                    push @mentions, $_->{'key'};
                }
            }
        }
    }

    timeular::debug_print("Tags:\n".Dumper(@tags), 3);
    timeular::debug_print("Mentions:\n".Dumper(@mentions), 3);
    return (\@tags, \@mentions);

}

### REPORT ###

# Generate report
sub get_report {

    my $stopped_after   = '';
    my $started_before  = '';
    my $timezone        = '';
    my $activity_id     = '';
    my $note_query      = '';
    my $file_type       = '';
        
    ($stopped_after, $started_before, $timezone, $activity_id, $note_query, $file_type) = @_;

    my %query           = (
        'timezone'    => $timezone,
        'activityID'  => $activity_id,
        'noteQuery'   => $note_query,
        'fileType'    => $file_type,
    ); 

    my $response = timeularREST::get_request_complex('/report', $stopped_after, $started_before, %query);

    # FIXME put report into file

}

1;
