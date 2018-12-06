package timeularPOST;

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

# Generic POST request
# Takes URL and Body as arguments
sub post_request {

    my $url     = '';
    my $body    = '';

    if (scalar(@_) == 2) {
        ($url, $body) = @_;
    } else {
        die "[ERROR] Argument error in post_request \n"
    }
    
    timeularREST::signin();

    $client->POST($url, $body, $headers);
    timeular::debug_print('POST "'.$client->getHost().$url, 2);
    timeular::debug_print("Request headers: ".join( ',', map { "$_:$headers->{$_}" } keys %$headers ), 3);
    timeular::debug_print('Body: '.$body, 3);

    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();
    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response code: ".$response_content, 3);

    if ($response_code == 200 || $response_code == 201) {
        return 1;
    } else {
        die "[ERROR] $response_content \n";
    }

}

### DEVICE ###

# set device to active
# no arguments required
sub post_device_active {

    my $device = timeularREST::get_device();

    if (timeularPOST::post_request("/devices/$device/active", "")) {
        print "Device updated successfully.\n";
        exit 0;
    } else {
        die "[ERROR] Device state update unsuccessful. \n";
    }

}

# disable device
# no arguments required
sub post_device_disabled {

    my $device = timeularREST::get_device();

    if (timeularPOST::post_request("/devices/$device/disabled", "")) {
        print "Device updated successfully.\n";
        exit 0;
    } else {
        die "[ERROR] Device state update unsuccessful. \n";
    }
    
}

### ACTIVITY ###

#create activity
# requires name and optional color
# autogenerate color if not present
sub post_activity {
    
    my $activity = {
        'name'          => '',
        'color'         => '',
        'integration'   => 'zei',
    };
    
    my $name    = $_[1];
    my $color   = $_[2];
    
    $activity->{'name'} = $name;
    if ($color) {
        $activity->{'color'} = $color;
    } else {
        $activity->{'color'} = "#".join("", map { sprintf "%02x", rand(255) } (0..2));
    }

    timeular::debug_print("Activity object: ".Dumper($activity), 3);
    timeularPOST::post_request('/activities', JSON->new->encode($activity));
    
}

# assign activity to device side
# requires activity id and device side (no body)
sub post_activity_assign {

    my $activity_id = '';
    my $device_side = '';

    ($activity_id, $device_side) = @_;

    timeular::debug_print("Assigning activity $activity_id to device side $device_side");
    if ( timeularPOST::post_request("/activities/$activity_id/device-side/$device_side", '') ) {
        print "Activity assigned to device.";
        exit 0;
    }

    exit 1;
}

### TRACKING & ENTRIES ###

# start tracking 
# requires activity id in url
# start timestamp in body optional
sub post_start_tracking {

    my $activity_id = '';
    my $started_at = '';
    my $body = {};

    if (scalar(@_) == 1) {
        ($activity_id) = @_;
        timeular::debug_print("Starting activity $activity_id");
    } else {
        ($activity_id, $started_at) = @_;
        timeular::debug_print("Starting activity $activity_id at timestamp $started_at");

        $body->{'startedAt'} = $started_at;
    }

    if ( timeularPOST::post_request("/tracking/$activity_id/start", JSON->new->encode($body)) ) {
        print "Tracking started.\n";
        exit 0;
    }
 
    exit 1;
}

# stop tracking 
# requires activity id in url
# stopped timestamp in body optional
sub post_stop_tracking {

    my $activity_id = '';
    my $stopped_at  = '';
    my $body        = {};

    if (scalar(@_) == 1) {
        ($activity_id) = @_;
        timeular::debug_print("stoping activity $activity_id");
    } else {
        ($activity_id, $stopped_at) = @_;
        timeular::debug_print("stoping activity $activity_id at timestamp $stopped_at");

        $body->{'stoppedAt'} = $stopped_at;
    }

    if ( timeularPOST::post_request("/tracking/$activity_id/stop", JSON->new->encode($body)) ) {
        print "Tracking stopped.\n";
        exit 0;
    }

    exit 1;
}


# create time entry
# requires the following properties in body:
# activity id, started at, stopped at, note (text, tags, mentions)
sub post_create_entry {

    my $activity_id = '';
    my $started_at  = '';
    my $stopped_at  = '';
    my $note        = '';
    my $activity    = {};

    if (scalar(@_) == 3) {
        ($activity_id, $started_at, $stopped_at) = @_;
    } else {
        ($activity_id, $started_at, $stopped_at, $note) = @_;
    }

   $activity = {
        'activityId'    => $activity_id,
        'startedAt'     => $started_at,
        'stoppedAt'     => $stopped_at,
    };

    print Dumper $activity;
    
    if ( timeularPOST::post_request("/time-entries", JSON->new->encode($activity)) ) {
        print "Entry created.\n";
        exit 0;
    }

    exit 1;
}

1;

