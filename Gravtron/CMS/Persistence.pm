package Gravtron::CMS::Persistence;
use Mojo::Base -base;

has 'gravtron';

sub find_categories {
    my ($self) = @_;

    my $home = $self->gravtron->config->{cms}->{home} . '/posts';

    opendir(my $dh, $home) or return undef;
    my @dirs = grep { -d "$home/$_" && !/\..?/ } readdir($dh);
    closedir($dh);
    return @dirs;
}

sub find_posts {
    my ($self, $categoria) = @_;

    my $home = $self->gravtron->config->{cms}->{home} . '/posts';
    
    my $dir = "$home/$categoria";

    opendir(my $dh, $dir) or return undef;
    my @files = 
    			map { s/\.post//; $_ }
    			grep { /\.post$/ } readdir($dh);
    closedir($dh);
    return @files;
}

sub read_post {
	my ($self, $categoria, $post_slug, $extra) = @_;

	my $home = $self->gravtron->config->{cms}->{home} . '/posts';
	my $prefix = $self->gravtron->config->{cms}->{prefix};

	my $filename = "$home/$categoria/$post_slug.post";
	my $file = $self->open_file($filename);

	unless ($file) {
		return undef, undef;
	}

	my ($info_text, $body) = split '↓↓↓', $file;

	my $info = {
		categoria => $categoria,
		post_slug => $post_slug,
		url => "$prefix/$categoria/$post_slug"
	};
	
	for my $line (split '\n', $info_text){

		my ($key, $value) = split '=>', $line;
		
		$key =~ s/^\s+//; $key =~ s/\s+$//;
		$value =~ s/^\s+//; $value =~ s/\s+$//;

		if ($key eq 'date'){
			my @arr = split '-', $value;
			$value = eval{ 
						DateTime->new(
							year 	=> $arr[0],
							month 	=> $arr[1],
							day 	=> $arr[2],
							locale 	=> "pt_BR"
						)
		 			};
		}
		$info->{$key} = $value;
	}

	my $post = $info;
	if ($body){
		$post->{body} = $body;
	}
	
	return $post;
}

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