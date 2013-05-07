package BTCE;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Digest::SHA qw( hmac_sha512_hex);
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
	my $lwp = $self->_lwp;
	my $resp = $lwp->get("https://btc-e.com/api/2/$sign/ticker");
	my $txt = $resp->content;
	my $jref = decode_json($txt);
	if(ref($jref) eq 'HASH' && exists($jref->{ticker})) {
		return $jref->{ticker};
	}
	return undef;
}

sub order_list {
	my($self) = @_;
	my $resp = $self->_authpost($self->_lwp, 'getInfo');
	my $jref = decode_json($resp->content);
	if(ref($jref) eq 'HASH' && exists($jref->{return})) {
		return $jref->{return};
	}
	return undef;
}

##############################################
# Returns a new, ssl enabled and UA faked LWP obj
sub _lwp {
	my $lwp = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1});
	$lwp->agent('Mozilla/4.76 [en] (Win98; U)');
	return $lwp;
}

##############################################
# Sends 'method' to TAPI using the given
# LWP object
sub _authpost {
	my($self, $lwp, $method) = @_;
	
	my $nonce = time;
	my $data  = "method=$method&nonce=$nonce";
	my $hash  = hmac_sha512_hex($data, $self->{secret});
	$lwp->default_header(Key=>$self->{key});
	$lwp->default_header(Sign=>$hash);
	my $resp = $lwp->post("https://btc-e.com/tapi", [method=>$method,, nonce=>$nonce]);
	return $resp;
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
