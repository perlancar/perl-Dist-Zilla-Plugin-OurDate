package Dist::Zilla::Plugin::OurDate;

use 5.010;
use strict;
use warnings;

# VERSION
# DATE

use Moose;
with (
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	},
);

has date_format => (is => 'rw', default => sub { '%Y-%m-%d' });

use namespace::autoclean;

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
                    "${1}our \$DATE = '$date'; $2"/emx and $munged_date++;

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

in dist.ini

	[OurDate]
	; optional, default is '%Y-%m-%d'
	date_format='%Y-%m-%d'

in your modules

	# DATE

or

	our $DATE = '2014-04-16'; # DATE


=head1 DESCRIPTION

This module is like L<Dist::Zilla::Plugin::OurVersion> except that it inserts
release date C<$DATE> instead of C<$VERSION>.


=head1 SEE ALSO

L<Dist::Zilla>
