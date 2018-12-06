package timeularPATCH;

use strict;
use warnings;
use warnings qw(all);

use LWP;
use JSON;
use REST::Client;
use HTTP::Cookies;
use Data::Dumper;
use Text::Table;

use timeular;
use timeularREST;

my $client      = $timeularREST::client;
my $headers     = $timeularREST::headers;
my $apikey      = $timeularREST::apikey;
my $apisecret   = $timeularREST::apisecret;
my $token       = $timeularREST::token;
my $serial      = $timeularREST::serial;

# Basic PATCH request
# Sets URL and authorization header
# Requires path, key and value to set
# Automatically calls sign in routine if token is empty
sub patch_request {

    my $path = '';
    my $key = '';
    my $value = '';
    
    if (scalar(@_) == 3) {
        ($path, $key, $value) = @_;
         timeular::debug_print("Patching path ".$path.": key=".$key." value=".$value, 2);
     } else {
        die "[ERROR] Argument error in patch_request \n";
     }

    if ($token eq '') {
        timeularREST::signin();
    }
    my $body_content = '{ "'.$key.'": "'.$value.'" }';

    $client->PATCH($path, $body_content, $headers);
    timeular::debug_print('PATCH "'.$client->getHost().$path, 2);
    timeular::debug_print('Body: '.$body_content, 3);
    timeular::debug_print("Request headers: ".join( ',', map { "$_:$headers->{$_}" } keys %$headers ), 3);

    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();
    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response code: ".$response_content, 3);
    
    if ($response_code == 200) {
        return 1;
    } else {
        die "[ERROR] $response_content \n";
    }
}

# More generic PATCH request
# Sets URL and authorization header
# Requires path and body 
# Automatically calls sign in routine if token is empty
sub patch_generic {

    my $path = '';
    my $body = '';
    
    if (scalar(@_) == 2) {
        ($path, $body) = @_;
         timeular::debug_print("Patching path ".$path." with body ".$body, 2);
     } else {
        die "[ERROR] Argument error in patch_request \n";
     }

    if ($token eq '') {
        timeularREST::signin();
    }

    $client->PATCH($path, $body, $headers);
    timeular::debug_print('PATCH "'.$client->getHost().$path, 2);
    timeular::debug_print('Body: '.$body, 3);
    timeular::debug_print("Request headers: ".Dumper($headers), 3);

    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();
    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response code: ".$response_content, 3);
    
    if ($response_code == 200) {
        return 1;
    } else {
        return 0;
    }
}


### DEVICE ###

# Modify device attributes
# Current supported attributes only "name"
sub patch_device {

    my $key = '';
    my $value = '';
    my $device = timeularREST::get_device();

    if (scalar(@_) == 2 && $device) {
        ($key, $value) = @_;
    } else {
        die "[ERROR] Argument error in patch_device \n";
    }

    print('Updated property "'.$key.'" with value "'.$value.'"'."\n");
    return timeularPATCH::patch_request('/devices/'.$device, $key, $value);
}

### ACTIVITY ###

# Modify activity
# Current supported attributes name and color
sub patch_activity {

    my $activity = '';
    my $key = '';
    my $value = '';

    if (scalar(@_) == 3) {
        ($activity, $key, $value) = @_;
    } else {
        die "[ERROR] Argument error in patch_device \n";
    }

    print('Updated activity '.$activity.' property "'.$key.'" with value "'.$value.'"'."\n");
    return timeularPATCH::patch_request('/activities/'.$activity, $key, $value);
}

### TRACKING & ENTRIES ###

# patch text of current if only text given as argument
# patch text of entry by id if id and text given
# delete text if empty
sub patch_text {

    my $id = '';
    my $value = '';
    my $activity = '';
    my $activity_obj = {};
    my $path = '';
    my $body_content = '';
    my $body = {};
    my $tags = ();
    my $mentions = ();

    if (scalar(@_) == 0) {

        $value = undef;
        timeular::debug_print("Updating current activity text to none...\n");

        $activity_obj = timeularREST::get_tracking();
        $activity = $activity_obj->{'activity'}->{'id'};
        $path = '/tracking/'.$activity;

    } elsif (scalar(@_) == 1) {

        ($value) = @_;
        timeular::debug_print("Updating current activity...\n");

        $activity_obj = timeularREST::get_tracking();
        $activity = $activity_obj->{'activity'}->{'id'};
        $path = '/tracking/'.$activity;

    } elsif (scalar(@_) == 2) {

        ($id, $value) = @_;
        timeular::debug_print("Updating entry $id ...\n");

        $activity_obj = timeularREST::get_entry($id);
        $activity = $activity_obj->{'id'};
        $path = '/time-entries/'.$activity;

    } else {
        die "[ERROR] Argument error in patch_tracking \n";
    }
        
    # contain tags and mentions on note update
    ($tags, $mentions) = timeularREST::get_entry_tags_and_mentions($id);
    timeular::debug_print("Tags: ".join(',', @$tags), 2);
    timeular::debug_print("Mentions: ".join(',', @$mentions), 2);

    if ($value) {
        $value = $value."\n";
    }
    foreach (@$tags) {
        $value = $value."#".$_." ";
        print "Value $value \n";
    }
    if ($value) {
        $value = $value."\n";
    }
    foreach (@$mentions) {
        $value = $value."@".$_." ";
        print "Value $value \n";
    }

    # set note object to value
    $activity_obj->{'note'}->{'text'} = $value;
    $body->{'note'} = $activity_obj->{'note'};

    if ( ! $body->{'note'}->{'tags'}) {
        timeular::debug_print("Tags undefined, inserting empty.", 3);
        $body->{'note'}->{'tags'} = [];
    }
    if ( ! $body->{'note'}->{'mentions'}) {
        timeular::debug_print("Tags undefined, inserting empty.", 3);
        $body->{'note'}->{'mentions'} = [];
    }

    $body_content = encode_json($body);

    timeular::debug_print("JSON Body: ".Dumper($body), 2);
    timeular::debug_print("Message Body: ".$body_content, 2);

    print("Successfully updated activity.\n");
    return timeularPATCH::patch_generic($path, $body_content);

}

# patch tags of current if only tags given as argument
# patch tags of entry by id if id and tags given
# delete tags if empty
sub patch_tags {

    my $id = '';
    my $value = '';
    my $activity = '';
    my $activity_obj = {};
    my $path = '';
    my $body_content = '';
    my $body = {};

    if (scalar(@_) == 0) {

        timeular::debug_print("Updating current activity tags to none...\n");

        $activity_obj = timeularREST::get_tracking();
        $activity = $activity_obj->{'activity'}->{'id'};

        $path = '/tracking/'.$activity;
        $body->{'note'} = $activity_obj->{'note'};
        $body->{'note'}->{'tags'} = [];

    } else {
        if (scalar(@_) == 1) {

            ($value) = @_;
            timeular::debug_print("Updating current activity...\n");

            $activity_obj = timeularREST::get_tracking();
            $activity = $activity_obj->{'activity'}->{'id'};
            $path = '/tracking/'.$activity;

        } elsif (scalar(@_) == 2) {

            ($id, $value) = @_;
            timeular::debug_print("Updating entry $id ...\n");

            $activity_obj = timeularREST::get_entry($id);
            $activity = $activity_obj->{'id'};
            $path = '/time-entries/'.$activity;

        } else {
            die "[ERROR] Argument error in patch_tracking \n";
        }

        my @values = ();
        my @tags = ();
        my $pos = 0;

        # Strip current tags from note    
        if ( $activity_obj->{'note'}->{'text'} ) {
            my $text = '';
            my @notes = split('\n', $activity_obj->{'note'}->{'text'} );

            foreach my $note (@notes) {
                $note =~ s/(#.+)//g ;
                $text = $text.$note;
            }

            $activity_obj->{'note'}->{'text'} = $text;
        }
           
        # If not setting to empty, insert tags in text 
        if ($value ne "") {
            timeular::debug_print("Fetching highest tag or mention index", 1);
            $pos = timeularREST::get_mention_index($id);
            
            @values = split(',', $value);
            if ( $activity_obj->{'note'}->{'text'} ) {
                $activity_obj->{'note'}->{'text'} = $activity_obj->{'note'}->{'text'}."\n";
            }

            foreach my $value (@values) {

                my @temp_array = ();
                my $temp_hashref = {};

                push @temp_array, $pos;
                push @temp_array, $pos + length($value);

                $value =~ s/^\s*(.*?)\s*$/$1/;

                if ( $activity_obj->{'note'}->{'text'} ) {
                    if ( $activity_obj->{'note'}->{'text'} !~ /#$value/ ) {
                        $activity_obj->{'note'}->{'text'} = $activity_obj->{'note'}->{'text'}."#".$value." ";
                    }
                } else {
                    $activity_obj->{'note'}->{'text'} = "#".$value." ";
                }

                $temp_hashref->{'indices'} = \@temp_array;
                $temp_hashref->{'key'}     = $value;

                push @tags, $temp_hashref;
                $pos = $pos + length($value) + 1;

            }
        }

        timeular::debug_print("Tags object: ".Dumper(@tags), 3);

        $activity_obj->{'note'}->{'tags'} = \@tags;
        $body->{'note'} = $activity_obj->{'note'};
    }

    if ( ! $body->{'note'}->{'mentions'}) {
        timeular::debug_print("Mentions undefined, inserting empty.", 3);
        $body->{'note'}->{'mentions'} = [];
    }


    $body_content = encode_json($body);

    timeular::debug_print("JSON Body: ".Dumper($body), 2);
    timeular::debug_print("Message Body: ".$body_content, 2);

    print('Updated activity '.$activity.' with tags "'.$value.'"'."\n");
    return timeularPATCH::patch_generic($path, $body_content);

}

# patch mentions of current if only mentions given as argument
# patch mentions of entry by id if id and mentions given
# delete mentions if empty
sub patch_mentions {

    my $id = '';
    my $value = '';
    my $activity = '';
    my $activity_obj = {};
    my $path = '';
    my $body_content = '';
    my $body = {};

    if (scalar(@_) == 0) {

        timeular::debug_print("Updating current activity mentions to none...\n");

        $activity_obj = timeularREST::get_tracking();
        $activity = $activity_obj->{'activity'}->{'id'};

        $path = '/tracking/'.$activity;
        $body->{'note'} = $activity_obj->{'note'};
        $body->{'note'}->{'mentions'} = [];

    } else {
        if (scalar(@_) == 1) {

            ($value) = @_;
            timeular::debug_print("Updating current activity...\n");

            $activity_obj = timeularREST::get_tracking();
            $activity = $activity_obj->{'activity'}->{'id'};
            $path = '/tracking/'.$activity;

        } elsif (scalar(@_) == 2) {

            ($id, $value) = @_;
            timeular::debug_print("Updating entry $id ...\n");

            $activity_obj = timeularREST::get_entry($id);
            $activity = $activity_obj->{'id'};
            $path = '/time-entries/'.$activity;

        } else {
            die "[ERROR] Argument error in patch_tracking \n";
        }

        my @values = ();
        my @mentions = ();
        my $pos = 0;

        # Strip current mentions from note    
        if ( $activity_obj->{'note'}->{'text'} ) {
            my $text = '';
            my @notes = split('\n', $activity_obj->{'note'}->{'text'} );

            foreach my $note (@notes) {
                $note =~ s/(@.+)//g ;
                $text = $text.$note;
            }

            $activity_obj->{'note'}->{'text'} = $text;
        }
           
        # If not setting to empty, insert mentions in text 
        if ($value ne "") {
            timeular::debug_print("Fetching highest tag or mention index", 1);
            $pos = timeularREST::get_tag_index($id);
        
            if ( $activity_obj->{'note'}->{'text'} ne '' ) {
                $activity_obj->{'note'}->{'text'} = $activity_obj->{'note'}->{'text'}."\n";
            }


            @values = split(',', $value);
            foreach my $value (@values) {

                my @temp_array = ();
                my $temp_hashref = {};

                push @temp_array, $pos;
                push @temp_array, $pos + length($value);

                $value =~ s/^\s*(.*?)\s*$/$1/;
                if ( $activity_obj->{'note'}->{'text'} ) {
                    if ( $activity_obj->{'note'}->{'text'} !~ /[@]$value/ ) {
                        $activity_obj->{'note'}->{'text'} = $activity_obj->{'note'}->{'text'}."@".$value." ";
                    }
                } else {
                    $activity_obj->{'note'}->{'text'} = "@".$value." ";
                }

                $temp_hashref->{'indices'} = \@temp_array;
                $temp_hashref->{'key'}     = $value;

                push @mentions, $temp_hashref;
                $pos = $pos + length($value) + 1;

            }
        }
        
        timeular::debug_print("mentions object: ".Dumper(@mentions), 3);

        $activity_obj->{'note'}->{'mentions'} = \@mentions;
        $body->{'note'} = $activity_obj->{'note'};
    }

    if ( ! $body->{'note'}->{'tags'}) {
        timeular::debug_print("tags undefined, inserting empty.", 3);
        $body->{'note'}->{'tags'} = [];
    }

    $body_content = encode_json($body);

    timeular::debug_print("JSON Body: ".Dumper($body), 2);
    timeular::debug_print("Message Body: ".$body_content, 2);

    print('Updated activity '.$activity.' with mentions "'.$value.'"'."\n");
    return timeularPATCH::patch_generic($path, $body_content);

}


1;

