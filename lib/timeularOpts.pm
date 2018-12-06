package timeularOpts;

use strict;
use warnings;
use warnings qw(all);

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Time::Format;
use Date::Manip;

use timeular;
use timeularREST;
use timeularPATCH;
use timeularPOST;
use timeularDELETE;

my $activities      = '';
my @activity_ass    = ();
my $activity_del    = '';
my @activity_unass  = ();
my $current         = '';
my @create_actv     = ();
my @create_entry    = ();
my $device          = '';
my $device_state    = '';
my @entries         = ();
my $entry           = '';
my $entry_del       = '';
my $patch_dev       = '';
my @patch_act       = ();
my @patch_text      = ();
my @patch_tags      = ();
my @patch_mentions  = ();
my $remove_dev      = '';
my @report          = ();
my @start           = ();
my @stop            = ();
my $tags            = '';

Getopt::Long::Configure ("bundling_values", "ignorecase_always");

GetOptions (    
                'activities|a'            => \$activities ,
                'assign-activity=s{2}'    => \@activity_ass,
                'create-activity=s{1,2}'  => \@create_actv,
                'create-entry|y=s{2,3}'   => \@create_entry,
                'current|c'               => \$current ,
                'delete-activity=s'       => \$activity_del,
                'delete-entry|d=s'        => \$entry_del,
                'device'                  => \$device ,
                'device-state=s'          => \$device_state ,
                'entries|e=s{2}'          => \@entries,
                'edit-device=s'           => \$patch_dev ,
                'edit-activity=s{2}'      => \@patch_act ,
                'edit-note|n=s{1,2}'      => \@patch_text, 
                'edit-tags|t=s{1,2}'      => \@patch_tags ,
                'edit-mentions|m=s{1,2}'  => \@patch_mentions ,
                'get-entry|g=s'           => \$entry,
                'get-tags'                => \$tags,
                'remove-device=s'         => \$remove_dev,
                'report|r=s{2,6}'         => \@report,
                'start|s=s{1,2}'          => \@start,
                'stop|o=s{1,2}'           => \@stop,
                'unassign-activity=s{2}'  => \@activity_unass,
                'verbose|v:i'             => \$timeular::DEBUG ,
            ) or print_usage();

sub eval_opts {

    timeular::debug_print('Debug lvl is '.$timeular::DEBUG);

### ACTIVITIES  ###

    if ($activities) {
        timeularREST::get_activities();
        exit 0;
    }

    if (@activity_ass) {
        timeularPOST::post_activity_assign(@activity_ass);
        exit 0;
    }

    if (@activity_unass) {
        timeularDELETE::delete_activity_assign(@activity_ass);
        exit 0;
    }

    if ($activity_del) {
        timeularDELETE::delete_activity($activity_del);
        exit 0;
    }

    if (@create_actv) {
        timeularPOST::post_activity(@create_actv);
        exit 0;
    }

### DEVICES ###

    if ($device) {
        timeularREST::get_device();
        exit 0;
    }
    
    # set device state
    if ($device_state) {
        if ($device_state eq 'active' ) {
            timeularPOST::post_device_active();
        } elsif ($device_state = 'inactive' ) {
            timeularDELETE::delete_device_active();
        } elsif ($device_state = 'enabled' ) {
            timeularDELETE::delete_device_disabled();
        } elsif ($device_state = 'diabled' ) {
            timeularPOST::post_device_disabled();
        } else {
            die "[ERROR] Device state $device_state unkown.\n";
        }
    }

    # expect --edit-device <key>=<value>
    if ($patch_dev) {
        if ($patch_dev =~ /\w+=\w+/) {
            my @args  = split /=/, $patch_dev;
            my $key   = $args[0];
            my $value = $args[1];
        
            timeularPATCH::patch_device($key, $value);
        } else {
            die "[ERROR] Argument error. \n";
        }
        exit 0;
    }

    if ($remove_dev) {
        timeularDELETE::delete_device($remove_dev);
        exit 0;
    }

### TRACKING & ENTRIES ###

    if ($current) {
        timeularREST::get_tracking();
        exit 0;
    }
    
    if ($entry) {
        timeularREST::get_entry($entry);
        exit 0;
    }
    
    if (@entries) {
        my $stopped_after = '';
        my $started_before = '';

        $stopped_after = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($entries[0])};
        $started_before = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($entries[1])};

        timeularREST::get_time_entries($stopped_after, $started_before);
        exit 0;
    }
    
    # expect --edit-text [entry_id] <text>
    if (@patch_text) {
        if (scalar(@patch_text) == 1) {
            timeularPATCH::patch_text($patch_text[0]);
            exit 0;
        } else {
            timeularPATCH::patch_text($patch_text[0], $patch_text[1]);
            exit 0;
        }
    }

    # expect --edit-tags [entry_id] <tags>
    if (@patch_tags) {
        if (scalar(@patch_tags) == 1) {
            timeularPATCH::patch_tags($patch_tags[0]);
            exit 0;
        } else {
            timeularPATCH::patch_tags($patch_tags[0], $patch_tags[1]);
            exit 0;
        }
    }

    # expect --edit-mentions [entry_id] <mentions>
    if (@patch_mentions) {
        if (scalar(@patch_mentions) == 1) {
            timeularPATCH::patch_mentions($patch_mentions[0]);
            exit 0;
        } else {
            timeularPATCH::patch_mentions($patch_mentions[0], $patch_mentions[1]);
            exit 0;
        }
    }
    
    if (@create_entry) {
        my $activity_id = '';
        my $started_at = '';
        my $stopped_at = '';

        $activity_id = $create_entry[0];
        $started_at = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($create_entry[1])};
        if ( scalar(@create_entry) == 2 ) {
            $stopped_at = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate('now')};
        } else {
            $stopped_at = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($create_entry[2])};
        }

        timeularPOST::post_create_entry($activity_id, $started_at, $stopped_at);
        exit 0;
    }

    if ($entry_del) {
        timeularDELETE::delete_entry($entry_del);
        exit 0;
    }
    
    if (@start) {

        my $activity_id = '';
        my $started_at = '';

        $activity_id = $start[0];
        $started_at = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($start[1])};

        timeularPOST::post_start_tracking($activity_id, $started_at);
        exit 0;
    }
    
    if (@stop) {

        my $activity_id = '';
        my $stopped_at = '';

        $activity_id = $stop[0];
        $stopped_at = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($stop[1])};

        timeularPOST::post_stop_tracking($activity_id, $stopped_at);
        exit 0;
    }
    

### REPORT ### 
    
    if (@report) {
        
        my $stopped_after = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($report[0])};
        my $started_before = $time{'yyyy-mm-ddThh:mm:ss.mmm', Date::Manip::ParseDate($report[1])};
        my $timezone = 'UTC';
        my $activity_id = '';
        my $note_query = '';
        my $file_type = 'csv';
        
        if ($report[2]) {
            if ($report[2] =~ /^\w+?(\/\w+)$/ ) {
                $timezone = $report[2];
            } else {
                die "Argument error.";
            }
        }
       if ($report[3]) {
            if ($report[3] =~ /^\d{7}$/ ) {
                $activity_id = $report[3];
            } else {
                die "Argument error.";
            }
        }
        if ($report[4]) {
            $timezone = $report[4];
        }
        if ($report[6]) {
            if ($report[6] =~ /csv|xlsx/) {
                $timezone = $report[6];
            } else {
                die "Argument error.";
            }
        }

        timeularREST::get_report($stopped_after, $started_before, $timezone, $activity_id, $note_query, $file_type);
        exit 0;
    }
    
    # get tags and mentions 
    if ($tags) {
        timeularREST::get_tags();
        exit 0;
    }

    # expect --edit-activity <acivity_id> <key>=<value>
    if (@patch_act) {
        if (scalar(@patch_act) == 2 && $patch_act[1] =~ /\w+=?#\w+/) {
            my $id    = $patch_act[0];
            my @args  = split /=/, $patch_act[1];
            my $key   = $args[0];   
            my $value = $args[1];

            timeularPATCH::patch_activity($id, $key, $value);
        } else {
            die "Argument error.";
        }
        exit 0;
    }
    
    print_usage();
}

sub print_usage {
    
    pod2usage( '
    Usage:
        timeularAPI.pl OPTIONS

    Activity Options:
        -a, --activities    List defined activities

            --assign-activity <activity_id> <device_side>
                            Assign activity to device side

            --create-activity <name> [ <color> ]
                            Create activity. If not specified color will be random
        
        -c, --current       Show current tracking activity
       
            --edit-activity <activity_id> [ name=<name> | color=#<rgb_color> ]
                            Edit activity name or color

            --unassign-activity <activity_id> <device_side>
                            Unassign activity from device side

            --delete-activity <activity_id>
                            Delete activity with ID

    Device Options:

            --device        Show known device

            --device-state active | inactive | enabled | disabled
                            Set device status to active/inactive or enable/disable device

            --edit-device name=<name>
                            Set device name

            --remove-device <device_serial>
                            Remove device by serial number

    Tracking & Entry Options:

        -y, --create-entry <activity_id> <started_at> [ <stopped_at> ]
                            Create entry with activity ID and start time.
                            If no stop time is provided current timestamp is used
                
        -e, --entries <stopped_after> <started_before>
                            Get saved time entries between stopped_after and started_before
                            Timestamp format is yyyy-mm-ddThh:mm:ss.sss

        -n, --edit-note [ <entry_id > ] [ <text> ]
                            Edit entry text: Without entry_id edits current tracking activity,
                            without any arguments removes text of currently tracking.

        -t, --edit-tags [ <entry_id> ] [ <tags> ]
                            Edit entry tags: Without entry_id edits current tracking activity,
                            without any arguments removes tags of currently tracking.

        -m, --edit-mentions [ <entry_id> ] [ <mentions> ]
                            Edit entry mentions: Without entry_id edits current tracking activity,
                            without any arguments removes mentions of currently tracking.

        -d, --delete-entry <entry_id>
                            Delete time entry by ID
        
        -g, --get-entry <entry_id>
                            Get time entry by id

            --get-tags      Get tags and mentions

        -s, --start <activity_id> [ <started_at> ]
                            Start activity by ID. Start timestamp optional

        -o, --stop <activity_id> [ <stopped_at> ]
                            Stop activity by ID. Stopped timestamp optional

        -r, --report <stopped_after> <started_before> [ <timezone> [ <activity_id> [ <note_query> [ <file_type> ] ] ] ]
                            Generate report with activities between stopped_after and started_before. 
                            Timezone default is UTC (format e.g. Europe/Berlin).
                            Optionally search for only given activity id or note string. 
                            Default file type is csv, xlsx supported.

    Global Options:

        -v, --verbose <level> 
                            Set verbosity level 

    REFERENCES:

        See https://timeular.com and http://developers.timeular.com/public-api/ for details on functionality and API
    ' );

}

1;
