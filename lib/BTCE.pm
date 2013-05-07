package BTCE;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Time::HiRes qw(gettimeofday);
use Digest::SHA qw( hmac_sha512_hex);
use JSON qw(decode_json);

##
## API CALLS
##

##############################################
# Returns ticker info for given currency bundle
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

##############################################
# Returns the current order list
sub order_list {
	my($self, %args) = @_;
	return $self->_raw_rpc('OrderList', %args);
}

##############################################
# Returns your own transaction history
sub trans_history {
	my($self, %args) = @_;
	return $self->_raw_rpc('TransHistory', %args);
}

##############################################
# Returns your transaction (=executed trades)
# history
sub trade_history {
	my($self, %args) = @_;
	return $self->_raw_rpc('TradeHistory', %args);
}

##############################################
# Returns info for this account
# (funds, permissions, etc)
sub get_info {
	my($self) = @_;
	return $self->_raw_rpc('getInfo');
}


##
## STUFF
##

##############################################
# returns a new BTCE object
sub new {
	my($classname, %args) = @_;
	my $self = { debug=>0, secret=>undef, key=>undef };
	bless($self, $classname);
	
	$self->{key}    = delete($args{key});
	$self->{secret} = delete($args{secret});
	$self->{nonce}  = time();
	$self->read_config if !defined($self->{key});
	
	return $self;
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


##
## INTERNAL
##


##############################################
# Generic TAPI wrapper
sub _raw_rpc {
	my($self, $command, %args) = @_;
	my $resp = $self->_authpost($self->_lwp, $command, %args);
	my $jref = decode_json($resp->content);
	if(ref($jref) eq 'HASH' && exists($jref->{return})) {
		return $jref->{return};
	}
	return undef;
}

##############################################
# Sends 'method' to TAPI using the given
# LWP object
sub _authpost {
	my($self, $lwp, $method, @optargs) = @_;
	
	unshift(@optargs, "method", $method);
	push(@optargs,    "nonce",  ++$self->{nonce});
	my $to_sign = "";
	
	for(my $i=int(@optargs); $i>0; $i-=2) {
		$to_sign = "$optargs[$i-2]=$optargs[$i-1]&$to_sign";
	}
	chop($to_sign); # last &
	print "## $to_sign\n";
	my $hash  = hmac_sha512_hex($to_sign, $self->{secret});
	$lwp->default_header(Key=>$self->{key});
	$lwp->default_header(Sign=>$hash);
	my $resp = $lwp->post("https://btc-e.com/tapi", \@optargs);
	return $resp;
}

##############################################
# Returns a new, ssl enabled and UA faked LWP obj
sub _lwp {
	my $lwp = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1});
	$lwp->agent('Mozilla/4.76 [en] (Win98; U)');
	return $lwp;
}


1;
