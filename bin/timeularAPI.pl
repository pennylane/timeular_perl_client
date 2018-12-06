#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(all);

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

use Data::Dumper;

use timeular;
use timeularOpts;

timeular::debug_print("Welcome to Timeular API utility");

timeularOpts::eval_opts();
