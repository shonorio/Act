package Act::Wiki;

use strict;
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::Default;
use Encode;
use DateTime::Format::Pg;

use Act::Config;
use Act::Wiki::Formatter;
use Act::Wiki::Store;

sub new
{
    return Wiki::Toolkit->new(
        store     => Act::Wiki::Store->new(map { $_ => $Config->get("wiki_$_") }
                                           qw(dbname dbuser dbpass)),
        formatter => Act::Wiki::Formatter->new(),
    );
}
sub format_node
{
    my ($wiki, $template, $content) = @_;

    my %metadata;
    my $cooked = encode("ISO-8859-1", $wiki->format($content, \%metadata));
    if ($metadata{chunks}) {
        $cooked = '[% PROCESS common %][% TAGS {% %} %]' . $cooked;
        my $output;
        $template->variables(chunks => $metadata{chunks});
        $template->process(\$cooked, \$output);
        return $output;
    }
    return $cooked;
}
sub display_node
{
    my ($wiki, $template, $node, $version) = @_;

    my %data = $wiki->retrieve_node(name => make_node_name($node), version => $version);
    $data{last_modified} = DateTime::Format::Pg->parse_datetime($data{last_modified})
        if $data{last_modified};

    $template->variables_raw(content => format_node($wiki, $template, $data{content}));
    $template->variables(node    => $node,
                         data    => \%data,
                         version => $version,
                         author  => Act::User->new( user_id => $data{metadata}{user_id}[0]),
    );
    $template->process('wiki/node');
}
sub make_node_name  { join ';', $Request{conference}, $_[0] }
sub split_node_name { (split ';', $_[0])[1] }

1;
__END__

=head1 NAME

Act::Wiki - Wiki utility routines

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut