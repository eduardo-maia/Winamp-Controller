#!/usr/bin/perl
# http://httpq.sourceforge.net/reference.html

package Winamp::Controller;

use LWP;
use LWP::UserAgent;
use URI::Encode;
use Moose;

our $VERSION = '0.0.3';

has 'host' =>
	(
	is => 'rw',
	isa => 'Str',
	default => '127.0.0.1'
	);

has 'port' =>
	(
	is => 'rw',
	isa => 'Int',
	default => 4800
	);

has 'password' =>
	(
	is => 'rw',
	isa => 'Str',
	required => 1
	);



=item set_password

Set the password to connect to Winamp httpQ plugin. Password is optional, and should be configured under Winamp httpQ settings.

=cut

sub set_password($)
{
my $self = shift;
$self->{password}=shift;
}




=item set_host

Set the host to connect to Winamp httpQ plugin. This is required. Host must be configured under Winamp httpQ settings.

=cut

sub set_host($)
{
my $self = shift;
$self->{host} = shift;
}





=item set_port

Set the port to connect to Winamp httpQ plugin, usually 4800. Port is a required parameter, and must be configured under Winamp httpQ settings.

=cut

sub set_port($)
{
my $self = shift;
$self->{port} = shift;
}




=item new

The constructor. Usage:

use Winamp::Controller;

my $winamp = new Winamp::Controller();
$winamp->set_host("127.0.0.1");
$winamp->set_port("4800");
$winamp->set_password("mypassword");

# Try to connect to Winamp and prints out httpQ version number
print $winamp->httpq_version();
=cut

sub new
{
my $invoker = shift;
my $class = ref($invoker) || $invoker;
my $self  = {};
$self->{'host'}=shift;
$self->{'port'}=shift;
$self->{'password'}=shift;
bless ($self, $class);
return $self;
}






##################################################
# sub __get_url
#
# INPUT: url address
#
# OUTPUT: 
# $hash{request_result} = 1 if success, 0 if fails
# $hash{page_html} = result, if connection succeeds
# $hash{error_message} = error message, if any
##################################################
sub __get_url($)
{
my $url = shift;
my %result;

# MAKES THE REQUEST
my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => $url);
$req->content_type('application/x-www-form-urlencoded');
my $res = $ua->request($req);

$result{request_result} = $res->is_success;

if ($res->is_success)
	{
	$result{page_html} = $res->content;
	}
else
	{
	$result{error_message} = $res->status_line . "\nCheck if Winamp httpQ service is running.";
	}

return %result;
}






# VALIDATE DATA
sub validate($)
{
my $self=shift;
my $result="";
if (!$self->{host})
	{
	$result .= "You need to specify host address.\n";
	}
if (!$self->{port})
	{
	$result .= "You need to specify port number (usually 4800).";
	}
return $result;
}







=item httpq_version

Get httpQ plugin version, or an error message if it fails

=cut

sub httpq_version()
{
my $self=shift;
my $error = validate($self);
return $error if ($error);

my %result = __get_url("http://$self->{host}:$self->{port}");
if ( $result{error_message} )
	{
	print $result{error_message};
	};
return $result{page_html};
}





=item chdir

Change the working direcotry to 'argument'. It returns 1 on success, 0 otherwise.

Usage:
use Winamp::Controller;
my $winamp = new Winamp::Controller('192.168.1.6','4800','mypassword');
$winamp->chdir('C:\Media\Mp3');

=cut

sub chdir($)
{
my $self=shift;
my $newdir=shift;
my $error = validate($self);
return $error if ($error);

my %result = __get_url("http://$self->{host}:$self->{port}/chdir?p=$self->{password}&dir=$newdir");
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}







=item clear

Clears the contents of the play list. It return 1 on success, 0 otherwise.

Usage:
use Winamp::Controller;
my $winamp = new Winamp::Controller('192.168.1.6','4800','mypassword');
$winamp->delete();

=cut

sub clear()
{
my $self=shift;
my $error = validate($self);
return $error if ($error);

my %result = __get_url("http://$self->{host}:$self->{port}/delete?p=$self->{password}");
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}







=item deletepos

Deletes the playlist item at index 'argument'. Note that the index of first music in your playlist is 0. It return 1 on success, 0 otherwise.

Usage:
use Winamp::Controller;
my $winamp = new Winamp::Controller('192.168.1.6','4800','mypassword');
$winamp->deletepos(0);

=cut

sub deletepos($)
{
my $self=shift;
my $pos=shift;
my $error = validate($self);
return $error if ($error);

my %result = __get_url("http://$self->{host}:$self->{port}/deletepos?p=$self->{password}&index=$pos");
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}









=item enqueuefile

Append a file to the playlist. The file must be in the current working directory or pass in the directory along with the filename as the argument. It return 1 on success, 0 otherwise.

Usage:
my $winamp = new Winamp::Controller('192.168.1.6','4800','mypassword');
$winamp->enqueuefile('D:\Media\MP3 Goth EBM 80s\Golden Apes - Denying The Towers Our Words Are Falling From [Full-lenght, 2010]\10 - Golden Apes - Denying The Towers Our ... - Invidia.mp3');

=cut

sub enqueuefile($$)
{
my $self=shift;
my $filepath=shift;
my $error = validate($self);
return $error if ($error);

my $uri = URI::Encode->new( { encode_reserved => 0 } );
$filepath= $uri->encode($filepath);

my $url="http://$self->{host}:$self->{port}/playfile?p=$self->{password}&file=$filepath";
#print "$url\n";
my %result = __get_url($url);
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}












=item generateplaylist

This method generates a playlist without repeating the same music. Better than shuffle option, which always repeats the same music again and again. Better than use winamp open dialog or Windows Explorer to load files, because the music will always be sorted by artist name. Great to broadcast your playlist.

This method receives as argument:
$_[0] = a path to a directory containing your music. It doesnt matter how many subdiretories are inside it, all mp3/wav/wma/ogg files will be loaded to Winamp.
$_[1] = random level, 1 or 2
        1 = A playlist will be generated mixing all files from all subdirectories. If you have a subdirectory with dance music mp3 files, other subdirectory with heavy metal, and other with world music, music styles will be mixed.
        2 = This method will randomize per subdirectory. So it will play first a music style, then other, then other.

It returns an array containing random paths to mp3 files.

Usage example:

use Winamp::Controller;
my $winamp = new Winamp::Controller('192.168.1.6','4800','passwordhere');
my @music = $winamp->generateplaylist('D:\Media\Radio\Music',2);
for (@music)
	{
	$winamp->enqueuefile($_);
	}

=cut

sub generateplaylist($$)
{
my $self=shift;
my $dir=shift;
my $random_level=shift;
my $error = validate($self);
return $error if ($error);

# DISCOVER ALL MP3 FILES RECURSIVELY
my @dirs = ($dir);
my @dirs_safe=();
my $dirs_total=0;
my %found_mp3_dir=();
my %found_mp3_all=();
my @arr_return=();
my @all_mp3_files=();

STUPID:
foreach my $currdir (pop(@dirs))
	{
	my @found_mp3=();
	$dirs_total++;
	$found_mp3_all{$currdir}=();
	
	opendir ( DIR, "$currdir" ) || die "Error in opening dir $dir\n";
	while( (my $filename = readdir(DIR)))
		{
		next if ($filename eq '.' || $filename eq '..');
		
		$filename=$currdir . "\\" . $filename;
		if (-d $filename)
			{
			push (@dirs,$filename);
			push (@dirs_safe,$filename);
			}
		elsif (-f $filename)
			{
			if ($filename=~/\.mp3$|\.wma$|\.wav$|\.ogg$/i)
				{
				my @temp=split(/\\/,$filename);
				delete $temp[scalar(@temp)-1];
				my $dir_path_tmp = join("\\",@temp);
				if (exists $found_mp3_dir{$dir_path_tmp} )
					{
					$found_mp3_dir{$dir_path_tmp}+=1; # stores a list of directories
					}
				else
					{
					$found_mp3_dir{$dir_path_tmp}=1;
					}
				push(@{$found_mp3_all{$currdir}},$filename); # stores a list of mp3 files per directory
				push(@all_mp3_files,$filename);
				}
			}
		else
			{
			die "$filename - not a file or directory?!\n";
			}
		}
	closedir(DIR);
	}
goto STUPID if (@dirs); # It pops only one time, need to force to go back to the beggining of interaction


if ($random_level == 1)
	{
	return @all_mp3_files;
	}
undef @all_mp3_files;


# TODO: generate a random number between elements existing inside an array
foreach my $dir (keys %found_mp3_dir)
	{
	#print "\n\n\nDirectory $dir\n";
	my %generated_randoms=();
	for (my $i=0;$i<$found_mp3_dir{$dir};$i++)
		{
		my $random_number = int (rand($found_mp3_dir{$dir})+0.5);
		
		# if some music that was selected before is selected again, just restart the randomize process
		if ($generated_randoms{$random_number})
			{
			$i--;
			next;
			}
		
		#TODO: don't generate playlist with repeated bands one music after other
		
		$generated_randoms{$random_number}=1;
		
		push(@arr_return,$found_mp3_all{$dir}[$random_number]);
		}
	}

return @arr_return;

}



=item play

Starts playing the playlist.

=cut

sub play($)
{
my $self = shift;
my $url="http://$self->{host}:$self->{port}/play?p=$self->{password}";
#print "$url\n";
my %result = __get_url($url);
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}



=item stop

Stops playing music. Like a click on Stop button.

=cut

sub stop($)
{
my $self = shift;
my $url="http://$self->{host}:$self->{port}/stop?p=$self->{password}";
#print "$url\n";
my %result = __get_url($url);
return $result{error_message} if ( $result{error_message} );
return $result{page_html};
}















1;
