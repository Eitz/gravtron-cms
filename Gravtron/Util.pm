package Gravtron::Util;
use FindBin;
use DateTime;

use Mojo::Base -base;

has 'app';

sub open_file {
	my ($self, $filename) = @_;
	my $file;
	$file = eval {
		  my $fh;
		  local $/ = undef;
		  open $fh, '<:encoding(utf8)', $filename;
		  my $content = <$fh>;
		  close $fh;
		  $content;
	};
	return $file;
}

1;