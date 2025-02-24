#!/usr/bin/perl
#
# FTCSV2QIF - converts Fidelity's SMA csv files to qif files
#
# Copyright © 2018 Stefanos Manganaris
#
# This software comes with absolutly NO WARRANTY of any kind.
#

die "Usage: $0 <filename> <acct name> <securities>\n" unless $#ARGV==2;

my $fname=$ARGV[0];
my $qacct=$ARGV[1];			# the account name to use in the QIF for import
my $semap=$ARGV[2];			# perl module mapping security name to Quicken names (optionally) - see, for example, Securities.pm
my $csv=$fname.".csv";			# csv input file
my $qif=$fname."-".$qacct.".qif";	# qif output file

die ("No such file $csv\n") if ! -f $csv;

use lib ".";				# add . to @INC
require $semap;

open(CSV,"<$csv") or die("Could not open $csv for reading. $!");
open(QIF,">$qif") or die("Could not open $qif for writing. $!");

print QIF "!Account\n";
print QIF "N$qacct\n";
print QIF "TInvst\n";
print QIF "^\n";
print QIF "!Type:Invst\n";

my %trans;

sub initTrans {
    return({date => "",
	    type => "",
	    security => "",
	    price => "",
	    qty => "",
	    invstamt => "",
	    totalamt => "",
	    memo => ""
	   });
}

sub printTrans {
  SWITCH: {
      if ($trans{'type'} =~ /^(Div|CGLong|CGShort)/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "Y$trans{'security'}\n";
	  print QIF "U$trans{'invstamt'}\n";
	  print QIF "T$trans{'totalamt'}\n";
	  #print QIF "M$trans{'memo'}\n";
	  print QIF "^\n";

	  last SWITCH;
      }
      if ($trans{'type'} =~ /^IntInc/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "U$trans{'invstamt'}\n";
	  print QIF "T$trans{'totalamt'}\n";
	 #print QIF "M$trans{'memo'}\n";
	  print QIF "^\n";

	  last SWITCH;
      }
      if ($trans{'type'} =~ /^Deposit/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "U$trans{'invstamt'}\n";
	  print QIF "T$trans{'totalamt'}\n";
	 #print QIF "M$trans{'memo'}\n";
	  print QIF "^\n";

	  last SWITCH;
      }
      if ($trans{'type'} =~ /^(Withdraw|MiscExp)/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "U$trans{'invstamt'}\n";
	  print QIF "T$trans{'totalamt'}\n";
	  print QIF "M$trans{'memo'}\n";
	  print QIF "^\n";

	  last SWITCH;
      }
      
      # otherwise #

      print QIF "D$trans{'date'}\n";
      print QIF "N$trans{'type'}\n";
      print QIF "Y$trans{'security'}\n";
      print QIF "I$trans{'price'}\n";
      print QIF "Q$trans{'qty'}\n";
      print QIF "U$trans{'invstamt'}\n";
      print QIF "T$trans{'totalamt'}\n";
      #print QIF "M$trans{'memo'}\n";
      print QIF "^\n";
    }
}

sub mapTType {
    local $_=shift;
    my $type;

  SWITCH: {
      if (/^\"?\s*YOU BOUGHT /) { $type="Buy"; last SWITCH; }
      if (/^\"?\s*YOU SOLD/) { $type="Sell"; last SWITCH; }
      if (/^\"?\s*DIVIDEND RECEIVED/) { $type="Div"; last SWITCH; }
      if (/^\"?\s*REINVESTMENT/) { $type="Buy"; last SWITCH; }
      if (/^\"?\s*LONG-TERM CAP GAIN/) { $type="CGLong"; last SWITCH; }
      if (/^\"?\s*SHORT-TERM CAP GAIN/) { $type="CGShort"; last SWITCH; }
      if (/^\"?\s*INTEREST EARNED/) { $type="IntInc"; last SWITCH; }
      if (/^\"?\s*Electronic Funds Transfer Received \(Cash\)/) { $type="Deposit"; last SWITCH; }
      if (/^\"?\s*TRANSFER OF ASSETS ACAT RES.CREDIT \(Cash\)/) { $type="Deposit"; last SWITCH; }
      if (/^\"?\s*NORMAL DISTR PARTIAL/) { $type="Withdraw"; last SWITCH; }
      if (/^\"?\s*DISTRIBUTION /) { $type="ShrsIn"; last SWITCH; }
      if (/^\"?\s*MERGER MER PAYOUT /) { $type="Sell"; last SWITCH; }
      if (/^\"?\s*ADVISORY FEE (Cash)/) { $type="MiscExp"; last SWITCH; }
      $type="??";
    }
    return($type);
}

sub cleanamt {
    local $_=shift;
    my ($amt) = /^\$?(.*)/;
    return(abs($amt));
}

sub cleandt {
    local $_=shift;
    my ($dt) = /^\s*(.*)/;
    return($dt);
}

sub cleansec {
    local $_=shift;
    my ($sec) = /^\s*(.*)\s*/;
    return($sec);
}

my $body=0;

while (<CSV>) {
  SWITCH: {
      if (/^Run Date,Action,Symbol,Description,Type,Exchange Quantity,Exchange Currency,Quantity,Currency,Price,Exchange Rate,Commission,Fees,Accrued Interest,Amount,Cash Balance,Settlement Date/) { $body=1; last SWITCH; }
      if ($body && /^\s*$/) { $body=0; last SWITCH; }
      if ($body) {
	  chop;
	  my ($rdate,$type,$cusip,$security,$sectype,$eqty,$ecurr,$qty,$curr,$price,$erate,$commision,$fees,$intrst,$amt,$cash,$sdate) = split ',';
	  if ($type =~ /^\s*PURCHASE INTO CORE ACCOUNT/) { last SWITCH; }	# ignore settlements in money market funds
 	  if ($type =~ /^\s*REDEMPTION FROM CORE ACCOUNT/) { last SWITCH; }	# ignore settlements in money market funds
	  else {
	      %trans = initTrans();
	      $trans{'date'}=cleandt($rdate);
	      $trans{'type'}=mapTType($type);
	      if ($semap{$cusip}) { $trans{'security'}=$semap{$cusip}; } else { $trans{'security'}=cleansec($cusip); }
	      $trans{'price'}=cleanamt($price);
	      $trans{'qty'}=abs($qty); 
	      $trans{'invstamt'}=cleanamt($amt);
	      $trans{'totalamt'}=cleanamt($amt);
	      $trans{'memo'}=$type;
	      printTrans();
	      last SWITCH;
	  }
      }
    }
}

close(CSV);
close(QIF);
