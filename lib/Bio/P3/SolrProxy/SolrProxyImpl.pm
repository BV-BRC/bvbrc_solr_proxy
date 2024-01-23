package Bio::P3::SolrProxy::SolrProxyImpl;
use strict;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

SolrProxy

=head1 DESCRIPTION



=cut

#BEGIN_HEADER

use Data::Dumper;
use Bio::P3::SolrProxy::AppConfig qw(:all);
use LWP::UserAgent;
use JSON::XS;

sub _get_schema
{
    my($self, $col) = @_;
    my $url = solr_url . "/$col/schema";

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get($url,
		       Accept => "*/*");
    if (!$res->is_success)
    {
	if ($res->code == 404)
	{
	    die "Invalid collection\n";
	}
	else
	{
	    warn "Error retrieving $url: " . $res->content;
	    die "Invalid collection\n";
	}
    }

    my $schema = decode_json($res->content);
    return $schema;
}

#
# Get the params needed for distributed queries for the collection.
# Returns (unique_key, field-list)
#
sub _get_collection_query_params
{
    my($self, $col) = @_;

    if (!$self->{param_cache}->{$col})
    {
	my $schema = $self->_get_schema($col);
	
	my $unique_key = $schema->{schema}->{uniqueKey};
	
	my @fields = grep { $_->{stored} } @{$schema->{schema}->{fields}};
	my @field_names = map { $_->{name} } @fields;
	
	@field_names = grep { $_ ne "_version_" } @field_names;

	$self->{param_cache}->{$col} = [$unique_key, \@field_names];
    }
    return @{$self->{param_cache}->{$col}};
}
    

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR


    #
    # Load permissions table.
    #

    my $fh;
    if (!open($fh, "<", collection_credentials_file))
    {
	die "Cannot open collection credentials file " . collection_credentials_file . ": $!";
    }

    $self->{permissions} = {};
    while (<$fh>)
    {
	chomp;
	my($col_name, $user, $perms) = split(/\s+/);
	if ($perms !~ /^[iud]+$/)
	{
	    die "Invalid permissions at line $. of " . collection_credentials_file;
	}
	my $phash = { map { $_ => 1 } split(//, $perms) };
	$self->{permissions}->{$col_name}->{$user} = $phash;
    }
    close($fh);

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}
=head1 METHODS
=head2 insert_records

  $success, $status_message = $obj->insert_records($collection_name, $records)

=over 4


=item Parameter and return types

=begin html

<pre>
$collection_name is a string
$records is a string
$success is an int
$status_message is a string
</pre>

=end html

=begin text

$collection_name is a string
$records is a string
$success is an int
$status_message is a string

=end text



=item Description


=back

=cut

sub insert_records
{
    my $self = shift;
    my($collection_name, $records) = @_;

    my @_bad_arguments;
    (!ref($collection_name)) or push(@_bad_arguments, "Invalid type for argument \"collection_name\" (value was \"$collection_name\")");
    (!ref($records)) or push(@_bad_arguments, "Invalid type for argument \"records\" (value was \"$records\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to insert_records:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	die $msg;
    }

    my $ctx = $Bio::P3::SolrProxy::Service::CallContext;
    my($success, $status_message);
    #BEGIN insert_records

   my $ua = LWP::UserAgent->new();

    #
    # Check permissions.
    #

    my $user = $ctx->user_id;

    if (!$self->{permissions}->{$user}->{$collection_name}->{i})
    {
	die "No permission for $user on $collection_name\n";
    }

    #
    # Validate collection is real
    #
    my($key, $fields) = $self->_get_collection_query_params($collection_name);
    $key or die "Collection not found\n";

    #
    # Ensure we can parse out our records, and that it is a list of hashes.
    #

    my $doc = decode_json($records);

    ref($doc) eq 'ARRAY' or die "Invalid record data format: must be array";
    grep { ref($_) ne 'HASH' } @$doc and die "Invalid record data format: must be array of hashes";

    my $url = solr_url . "/$collection_name/update";
    my $res = $ua->post($url,
			"Content-Type" => 'application/json',
			Content => $records);

    
    #END insert_records
    my @_bad_returns;
    (!ref($success)) or push(@_bad_returns, "Invalid type for return variable \"success\" (value was \"$success\")");
    (!ref($status_message)) or push(@_bad_returns, "Invalid type for return variable \"status_message\" (value was \"$status_message\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to insert_records:\n" . join("", map { "\t$_\n" } @_bad_returns);
	die $msg;
    }
    return($success, $status_message);
}


=head2 update_records

  $success, $status_message = $obj->update_records($collection_name, $records)

=over 4


=item Parameter and return types

=begin html

<pre>
$collection_name is a string
$records is a string
$success is an int
$status_message is a string
</pre>

=end html

=begin text

$collection_name is a string
$records is a string
$success is an int
$status_message is a string

=end text



=item Description


=back

=cut

sub update_records
{
    my $self = shift;
    my($collection_name, $records) = @_;

    my @_bad_arguments;
    (!ref($collection_name)) or push(@_bad_arguments, "Invalid type for argument \"collection_name\" (value was \"$collection_name\")");
    (!ref($records)) or push(@_bad_arguments, "Invalid type for argument \"records\" (value was \"$records\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to update_records:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	die $msg;
    }

    my $ctx = $Bio::P3::SolrProxy::Service::CallContext;
    my($success, $status_message);
    #BEGIN update_records

    my $ua = LWP::UserAgent->new();

    #
    # Check permissions.
    #

    my $user = $ctx->user_id;

    if (!$self->{permissions}->{$user}->{$collection_name}->{u})
    {
	die "No permission for $user on $collection_name\n";
    }

    #
    # Validate collection is real
    #
    my($key, $fields) = $self->_get_collection_query_params($collection_name);
    $key or die "Collection not found\n";

    #
    # Ensure we can parse out our records, and that it is a list of hashes.
    #

    my $doc = decode_json($records);

    ref($doc) eq 'ARRAY' or die "Invalid record data format: must be array";
    grep { ref($_) ne 'HASH' } @$doc and die "Invalid record data format: must be array of hashes";

    #
    # Ensure all records have a value for our key
    #

    grep { exists $_->{$key} } @$doc or die "Unique key must be specified on insert";

    my $url = solr_url . "/$collection_name/update?commit=true";
    my $res = $ua->post($url,
			"Content-Type" => 'application/json',
			Content => $records);

    if (!$res->is_success)
    {
	die "Error processing update: " . $res->content;
    }
    print STDERR "Processed update: " . $res->content;

    #END update_records
    my @_bad_returns;
    (!ref($success)) or push(@_bad_returns, "Invalid type for return variable \"success\" (value was \"$success\")");
    (!ref($status_message)) or push(@_bad_returns, "Invalid type for return variable \"status_message\" (value was \"$status_message\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to update_records:\n" . join("", map { "\t$_\n" } @_bad_returns);
	die $msg;
    }
    return($success, $status_message);
}





=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}



=head1 TYPES


=cut

1;
