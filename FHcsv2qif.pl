#!/usr/bin/perl
#
# FHCSV2QIF - converts Fidelity's HSA csv files to qif files
#
# Copyright © 2018 Stefanos Manganaris
#
# This software comes with absolutly NO WARRANTY of any kind.
#

die "Usage: $0 <filename> <acct name> <securities>\n" unless $#ARGV==2;

my $fname=$ARGV[0];
my $qacct=$ARGV[1];			# the account name to use in the QIF for import
my $semap=$ARGV[2];			# perl module mapping security name to Quicken names - see, for example, CollegeAdvantage.pm
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
      if ($trans{'type'} =~ /^(Div|CGLong)/) {

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
      if ($trans{'type'} =~ /^Withdraw/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "U$trans{'invstamt'}\n";
	  print QIF "T$trans{'totalamt'}\n";
	 #print QIF "M$trans{'memo'}\n";
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
      if (/^\s*YOU BOUGHT /) { $type="Buy"; last SWITCH; }
      if (/^\s*REINVESTMENT/) { $type="Buy"; last SWITCH; }
      if (/^\s*LONG-TERM CAP GAIN/) { $type="CGLong"; last SWITCH; }
      if (/^\s*INTEREST EARNED/) { $type="IntInc"; last SWITCH; }
      if (/^\s*CO CONTR CURRENT YR\s+EMPLOYER CUR YR/) { $type="Deposit"; last SWITCH; }
      if (/^\s*NORMAL DISTR PARTIAL/) { $type="Withdraw"; last SWITCH; }
      if (/^\s*YOU SOLD/) { $type="Sell"; last SWITCH; }
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

my $body=0;

while (<CSV>) {
  SWITCH: {
      if (/^Run Date,Action,Symbol,Security Description,Security Type,Quantity,Price \(\$\),Commission \(\$\),Fees \(\$\),Accrued Interest \(\$\),Amount \(\$\),Settlement Date/) { $body=1; last SWITCH; }
      if ($body && /^\s*$/) { $body=0; last SWITCH; }
      if ($body) {
	  chop;
	  my ($rdate,$type,$cusip,$security,$sectype,$qty,$price,$commision,$fees,$intrst,$amt,$sdate) = split ',';
	  if ($type =~ /^\s*PARTIC CONTR CURRENT PARTICIPANT CUR YR/) { last SWITCH; }					# already recorded
	  if ($type =~ /^\s*PURCHASE INTO CORE ACCOUNT FDIC INSURED DEPOSIT AT CITIBANK/) { last SWITCH; }		# ignore transfers between cash accounts
	  if ($type =~ /^\s*PURCHASE INTO CORE ACCOUNT FDIC INSURED DEPOSIT AT WELLS FARGO/) { last SWITCH; }		# ignore transfers between cash accounts
	  if ($type =~ /^\s*REDEMPTION FROM CORE ACCOUNT FDIC INSURED DEPOSIT AT CITIBANK/) { last SWITCH; }		# ignore transfers between cash accounts
	  if ($type =~ /^\s*REDEMPTION FROM CORE ACCOUNT FDIC INSURED DEPOSIT AT WELLS FARGO/) { last SWITCH; }		# ignore transfers between cash accounts
	  else {
	      %trans = initTrans();
	      $trans{'date'}=cleandt($rdate);
	      $trans{'type'}=mapTType($type);
	      $trans{'security'}=$semap{$security};
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
