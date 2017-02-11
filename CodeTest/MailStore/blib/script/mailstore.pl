#!/opt/loki/perl/perls/perl-5.24.0/bin/perl 
#-------------------------------------------------------
#  File: mailstore.pl
#  Description: mailstore is a command line tool to 
#               service mail copy functionality
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#--------------------------------------------------------

use strict;

sub BEGIN {
  use File::Basename 'dirname';
  use File::Spec::Functions qw(splitdir);

  # Source directory has precedence
  my @base = (splitdir(dirname(__FILE__)), '..');
  my $lib = join('/', @base, 'lib');
  unshift(@INC, $lib);
}

use Getopt::Long;
use FindBin;
use Data::Dumper;

# Importing project libraries
#
use MailStore;
use MailStore::Service;

# Set fflush on stdout...
$| = 1;

sub main {
    my %arg = ();

    # now get user options
    GetOptions(
        'maildir=s'         => \$arg{maildir},
        'show-message=s'    => \$arg{messageId},
        'show-dir=s'        => \$arg{messageDir},
        'help|?'            => \$arg{help},
    );

    usage() if ($arg{help});

    print "\n".'Starting MailStore....'."\n";
    my $service = MailStore::Service->new(%arg);
    #
    # Reporting purpose
    #
    if($arg{messageDir}) {
        $service->get_dir_data();
    }
    elsif($arg{messageId}) {
        $service->get_message_data();
    }
    else {
        #
        # Discarding noise, useful in debugging
        #
        local *STDERR;
        open STDERR, ">>", '/dev/null';
        #
        # Runs the service - Mail Extraction and Storage
        #
        $service->run();
        close STDERR;
    }
    
    print "\n".'Finished running MailStore'."\n";
    return;
}

#
# Help - Usage
#
sub usage {
  print <<USAGE;

mailstore v$MailStore::VERSION
About: Command-line client for MailStore project
Usage: mailstore [options]

Options:
  --help                   - Get help
  --maildir        <dir>   - Base path for maildir directory 
  --show-message   <id>    - Provide a messageId of the stored message
  --show-dir       <dir>   - Provide the directory path of the stored message
USAGE
    return;
}

main();
exit;   # End of the code