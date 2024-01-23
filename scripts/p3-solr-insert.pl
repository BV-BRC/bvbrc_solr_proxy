#
# Insert records via the solr proxy
#

use strict;
use Getopt::Long::Descriptive;
use Bio::P3::SolrProxy::Client;
use File::Slurp;
use JSON::XS;
use Try::Tiny;

my($opt, $usage) = describe_options("%c %o collection data-file",
				    ["update" => "Update existing records"],
				    ["insert" => "Insert new records"],
				    ["url=s" => "Use this service URL instead of the default"],
				    ["help|h" => "Show this help message"]);

print($usage->text), exit 0 if $opt->help;
die($usage->text) if @ARGV != 2;

my $mode;
if (!($opt->update xor $opt->insert))
{
    die "One of --update or --insert must be provided\n";
}

my $collection = shift;
my $data_file = shift;

my $client = Bio::P3::SolrProxy::Client->new($opt->url);

my $data;
try {
    $data = eval { read_file($data_file); };
} catch {
    die "Error reading data file $data_file\n";
};

my $doc;
try {
    $doc = decode_json($data);
} catch {
    die "Error parsing $data_file: $_";
};
#
# Some simple validation
#
ref($doc) eq 'ARRAY' or die "Invalid record data format: must be array";
grep { ref($_) ne 'HASH' } @$doc and die "Invalid record data format: must be array of hashes";

#
# And go
#

if ($opt->insert)
{
    $client->insert_records($collection, $data);
}
elsif ($opt->update)
{
    $client->update_records($collection, $data);
}
