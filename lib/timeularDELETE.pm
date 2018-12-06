package timeularDELETE;

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

# Generic DELETE request
# Takes URL as argument
sub delete_request {

    my $url = '';

    if (scalar(@_) == 1) {
        ($url) = @_;
    } else {
        die "[ERROR] Argument error in delete_request \n"
    }
    
    timeularREST::signin();

    $client->DELETE($url, $headers);
    timeular::debug_print("DELETE ".$client->getHost().$url , 2);
    timeular::debug_print("Request headers: ".join( ',', map { "$_:$headers->{$_}" } keys %$headers ), 3);

    my $response_code = $client->responseCode();
    my $response_content = $client->responseContent();
    timeular::debug_print("Response code: ".$response_code, 2);
    timeular::debug_print("Response content: ".$response_content, 3);

    if ($response_code == 200) {
        return 1;
    } else {
        die "[ERROR] $response_content \n";
    }

}

### DEVICE ###

# set device to active
# no arguments required
sub delete_device_active {

    my $device = timeularREST::get_device();

    if (timeularDELETE::delete_request("/devices/$device/active")) {
        print "Device updated successfully.\n";
        exit 0;;
    }

    exit 1;
}

# disable device
# no arguments required
sub delete_device_disabled {

    my $device = timeularREST::get_device();

    if (timeularDELETE::delete_request("/devices/$device/disabled")) {
        print "Device updated successfully.\n";
        exit 0;
    }
   
   exit 1; 
}

# remove device 
# requires device serial
sub delete_device {

    my $device_serial = '';
    ($device_serial) = @_;

    print("Are you sure you want to remove device $device_serial ? [yes|NO] ");
    my $response = <STDIN> ;
    chomp $response;

    if ($response =~ /^yes|YES$/) {
        timeularDELETE::delete_request("/devices/$device_serial");
        print "Device removed. \n";
        exit 0;
    }

    # FIXME sth not yet working

    exit 1;
}


### ACTIVITIES ###

# archive activity
# requires activity id 

sub delete_activity {
    my $activity_id = '';
    ($activity_id) = @_;

    timeular::debug_print("Deleting activity $activity_id");
    if ( timeularDELETE::delete_request("/activities/$activity_id") ) {
        print "Activity deleted.";
        exit 0;
    }

    exit 1;
}

# unassign activity from device side
# requires activity id and device side (in url)
# device side to be referred from activity query

sub delete_activity_assign {

    my $activity_id = '';
    my $device_side = '';

    ($activity_id, $device_side) = @_;

    timeular::debug_print("Assigning activity $activity_id to device side $device_side");
    if ( timeularPOST::delete_request("/activities/$activity_id/device-side/$device_side") ) {
        print "Activity unassigned from device.";
        exit 0;
    }

    exit 1;
}


### TRACKING & ENTRIES ###

# delete time entry
# requires entry id 
sub delete_entry {

    my $entry = '';
    ($entry) = @_;

    if (timeularDELETE::delete_request("/time-entries/$entry")) {
        print "Entry deleted.\n";
        exit 0;
    }

    exit 1;
}

1;

