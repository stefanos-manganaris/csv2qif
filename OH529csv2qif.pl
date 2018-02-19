#!/usr/bin/perl
#
# OH529CSV2QIF - converts Ohio's 529 College Advantage csv files to qif files
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
      if ($trans{'type'} =~ /^Div/) {

	  print QIF "D$trans{'date'}\n";
	  print QIF "N$trans{'type'}\n";
	  print QIF "Y$trans{'security'}\n";
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
      print QIF "M$trans{'memo'}\n";
      print QIF "^\n";
    }
}

sub mapTType {
    local $_=shift;
    my $type;

  SWITCH: {
      if (/^Exchange In Age-Based/) { $type="Buy"; last SWITCH; }
      if (/^Exchange Out Age-Based/) { $type="Sell"; last SWITCH; }
      if (/^Contribution AIP/) { $type="Buy"; last SWITCH; }
      if (/^Qualified w\/d Bene/) { $type="SellX"; last SWITCH; }
      if (/^Qualified w\/d Acct Owner/) { $type="SellX"; last SWITCH; }
      $type="??";
    }
    return($type);
}

sub cleanamt {
    local $_=shift;
    my ($amt) = /^\$(.*)/;
    return(abs($amt));
}

my $header=0;
my $body=0;

while (<CSV>) {
  SWITCH: {
      if (/^Fund Account Number,Fund Name,Price,Shares,Total Value$/) { $header=1; last SWITCH; }
      if (/^Account Number,Trade Date,Process Date,Transaction Type,Transaction Description,Investment Name,Share Price,Shares,Gross Amount,Net Amount/) { $body=1; last SWITCH; }
      if ($body) {
	  chop;
	  %trans = initTrans();
	  my ($acct,$tdate,$pdate,$type,$memo,$security,$price,$qty,$grossamt,$netamt) = split ',';
	  $trans{'date'}=$tdate;
	  $trans{'type'}=mapTType($type);
	  $trans{'security'}=$semap{$security};
	  $trans{'price'}=cleanamt($price);
	  $trans{'qty'}=abs($qty); 
	  $trans{'invstamt'}=cleanamt($grossamt);
	  $trans{'totalamt'}=cleanamt($netamt);
	  $trans{'memo'}=$memo;
	  printTrans();
	  last SWITCH;
      }
    }
}

close(CSV);
close(QIF);
