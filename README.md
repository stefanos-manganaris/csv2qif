CSV2QIF - converts csv files to qif files

Copyright © 2018 Stefanos Manganaris

IMPORTANT NOTES

You may find these converters useful if you use old accounting software
to track your investment transactions that can import .qif files, but
not .csv files. Many financial institutions provide .csv files, in
various formats, and no longer provide .qif files.

This software comes with absolutly NO WARRANTY of any kind.

These converters are known to work well with csv files provided by
Ohio's 529 savings program, College Advantage, for certain types of
accounts, and for certain types of investment transactions.  It is
almost certain that it does NOT cover the full spectrum of
institutions, accounts, and transactions.  Contributions that enhance
its functionality are welcome.

REQUIREMENTS

* [Perl 5](https://www.perl.org/)

USAGE

    OH529csv2qif.pl "filename" "acct name" "securities"

The converter reads the contents of "filename".csv and creates
"filename"-"acct name".qif as output.  The csv file is not changed.
If the qif file exists, it is overwritten.

Imports from qif files require a single destination account in your
accounting software.  Specify the destination account as "acct name".

The "securities" argument should refer to a perl module that defines a
mapping between security names used by your financial institution and
security names used by your accounting software.  See the provided
Securities.pm module for an example. Investment transactions are
exported into the qif file using the security names you specify in
this module, to match those defined in your accounting software.

MANIFEST

	OH529csv2qif.pl		CSV to QIF converter - Ohio's 529, College Advantage
	Securities.pm		example - mapping CSV security names to QIF security names

CONTACT

stefanos.manganaris at gmail.com
