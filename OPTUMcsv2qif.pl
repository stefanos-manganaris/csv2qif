#!/usr/bin/perl
#
# OPTUMcsv2qif - converts Optum's HSA csv files to qif files
#
# Copyright © 2019 Stefanos Manganaris
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
      if (/^\s*INVESTMENT PURCHASE/) { $type="Buy"; last SWITCH; }
      if (/^\s*REINVESTED DIVIDEND/) { $type="ReinvDiv"; last SWITCH; }
      if (/^\s*INVESTMENT WITHDRAWAL/) { $type="Sell"; last SWITCH; }
      if (/^\s*LONG-TERM CAP GAIN/) { $type="CGLong"; last SWITCH; }				# placeholder
      if (/^\s*INTEREST EARNED/) { $type="IntInc"; last SWITCH; }				# placeholder
      if (/^\s*CO CONTR CURRENT YR  EMPLOYER CUR YR/) { $type="Deposit"; last SWITCH; }		# placeholder
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
    my ($dt) = /^\s*(.*)\s*$/;
    $dt =~ s/(.*)18$/${1}2018/;
    $dt =~ s/(.*)19$/${1}2019/;
    $dt =~ s/(.*)20$/${1}2020/;
    return($dt);
}

my $body=0;

while (<CSV>) {
  SWITCH: {
      if (/^Date,FundName,TransName,Units,Amount,Price,Source/) { $body=1; last SWITCH; }
      if ($body && /^\s*$/) { $body=0; last SWITCH; }
      if ($body) {
	  chop;
	  my ($date,$security,$type,$qty,$amt,$price,$account) = split ',';
	  %trans = initTrans();
	  $trans{'date'}=cleandt($date);
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

close(CSV);
close(QIF);
