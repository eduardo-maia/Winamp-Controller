#!/usr/bin/perl
use Winamp::Controller;

# connect to Winamp
my $winamp = new Winamp::Controller();
$winamp->set_host("127.0.0.1");
$winamp->set_port("4800");
$winamp->set_password("mypassword");

# stop playing music, if any
$winamp->stop();

# clear your playlist
$winamp->clear();

# each element from @music array is a path to a random mp3 file
my @music = $winamp->generateplaylist('C:\Backup\Media\MP3 Freestyle',2);
for (@music)
	{
	# enqueue a file on WinAmp
	$winamp->enqueuefile($_) if ($_ =~ /\.mp3$/);
	}

# starts playing
$winamp->play();