package Dist::Zilla::Plugin::OurDate;

use 5.010001;
use strict;
use warnings;

use POSIX ();

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
);

has date_format => (is => 'rw', default => sub { '%Y-%m-%d' });

use namespace::autoclean;

# AUTHORITY
# DATE
# DIST
# VERSION

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ( $self, $file ) = @_;

    if ( $file->name =~ m/\.pod$/ixms ) {
        $self->log_debug( 'Skipping: "' . $file->name . '" is pod only');
        return;
    }

    # so it doesn't differ from file to file
    state $date = POSIX::strftime($self->date_format, localtime());

    my $content = $file->content;

    my $end_pos = $content =~ /^(__DATA__|__END__)$/m ? $-[0] : undef;

    my $munged_date = 0;
    $content =~ s/
                     ^
                     (\s*)           # capture all whitespace before comment

                     (?:our [ ] \$DATE [ ] = [ ] '[^']+'; [ ] )?  # previously produced output
                     (
                         \#\s*DATE     # capture # DATE
                         \b            # and ensure it ends on a word boundary
                         [             # conditionally
                             [:print:]   # all printable characters after DATE
                             \s          # any whitespace including newlines see GH #5
                         ]*            # as many of the above as there are
                 )
                 $               # until the EOL}xm
                 /

                     !defined($end_pos) || $-[0] < $end_pos ?

                     "${1}our \$DATE = '$date'; $2"

                     :

                     $&

                     /emx and $munged_date++;

    if ( $munged_date ) {
        $self->log_debug([ 'adding $DATE assignment to %s', $file->name ]);
        $file->content($content);
    }
    else {
        $self->log_debug( 'Skipping: "'
                              . $file->name
                              . '" has no "# DATE" comment'
                          );
    }
    return;
}
__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: no line insertion and does Package release date with our

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<dist.ini>:

	[OurDate]
	; optional, default is '%Y-%m-%d'
	date_format=%Y-%m-%d

in your modules:

	# DATE

or

	our $DATE = '2014-04-16'; # DATE


=head1 DESCRIPTION

This module is like L<Dist::Zilla::Plugin::OurVersion> except that it inserts
release date C<$DATE> instead of C<$VERSION>.

Comment/directive below C<__DATA__> or C<__END__> will not be replaced.


=head1 SEE ALSO

L<Dist::Zilla>
