package BTCE;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON qw(decode_json);

##############################################
# returns a new BTCE object
sub new {
	my($classname, %args) = @_;
	my $self = { debug=>0, secret=>undef, key=>undef };
	bless($self, $classname);
	
	$self->{key}    = delete($args{key});
	$self->{secret} = delete($args{secret});
	
	$self->read_config if !defined($self->{key});
	
	return $self;
}


sub ticker {
	my($self, $sign) = @_;
	my $lwp = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1});
	$lwp->agent('Mozilla/4.76 [en] (Win98; U)');
	my $resp = $lwp->get("https://btc-e.com/api/2/$sign/ticker");
	my $txt = $resp->content;
	my $jref = decode_json($txt);
	if(ref($jref) eq 'HASH' && exists($jref->{ticker})) {
		return $jref->{ticker};
	}
	return undef;
}





##############################################
# (Re-?)read config file in user home directory
sub read_config {
	my($self) = @_;
	$self->debug("Attempting to get secret from config file");
	
	open(CF, "<", "$ENV{HOME}/.btce.secret") or return undef;
	my $key = <CF>;
	my $sec = <CF>;
	close(CF);
	
	if(defined($sec)) {
		chomp($key);
		chomp($sec);
		$self->{key} = $key;
		$self->{secret} = $sec;
		$self->debug("initialized with key=$key");
	}
}

##############################################
# Dynamically enables or disables debugging
sub enable_debug {
	my($self, $val) = @_;
	$self->{debug} = ($val ? 1 : 0);
}

##############################################
# Printout a debug message if debugging is
# enabled
sub debug {
	my($self, @msg) = @_;
	return unless $self->{debug};
	print "debug: ".join(" ", @msg)."\n";
}


1;
