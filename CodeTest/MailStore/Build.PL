#!/usr/bin/perl

use warnings;
use strict;
use Module::Build;
use File::Find;

my $build = Module::Build->new(
    module_name        => 'MailStore',
    license            => 'gpl',
    dist_author        => ['Babu Prasad <bprasadh@gmail.com>'],
    dist_abstract      => 'Messages extraction and storage toolkit',
    configure_requires => {
        'strict'        => '1.11',
        'warnings'      => '1.36',
        'Module::Build' => '0.4220',
        'File::Find'    => '1.34',
        'File::Copy'    => '2.31',
        'File::Path'    => '2.12_01'
    },
    requires => {
        'App::cpanminus'      => '1.7042',
        'Moose'               => '2.2004',
        'Log::Log4perl'       => '1.48',
        'Data::Dumper'        => '2.161',
        'Mail::Box::Manager'  => '3.001',
        'Mail::Message::Body' => '3.000',
        'YAML::Dumper'        => undef,
        'FindBin'             => '1.51',
        'File::Slurp'         => '9999.19',
        'Try::Tiny'           => '0.28',
        'Storable'            => '2.56',
        'File::Spec'          => '3.63',
        'Mail::Address'       => '2.18',
        'Exporter'            => '5.72',
        'Moose::Role'         => '2.2004',
        'base'                => '2.23',
        'Config::Simple'      => '4.58',
        'Carp'                => '1.40',
        'YAML'                => '1.21',
    },

    #
    # We are not installing anything here
    # We are using this to mainly run installdeps
    #
    #  install_path => {
    #    'bin' => "$base_dir/bin",
    #    'etc' => "$base_dir/etc",
    #  },
);
$build->create_build_script();

# End of Build.PL
