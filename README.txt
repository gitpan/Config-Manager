                   =========================================
                     Package "Config::Manager" Version 1.4
                   =========================================


             Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
                             All rights reserved.


This package is available for download either from the web site at

                  http://www.engelschall.com/u/sb/download/

or from any CPAN (= "Comprehensive Perl Archive Network") mirror server:

               http://www.perl.com/CPAN/authors/id/S/ST/STBEY/


What's new in version 1.4:
--------------------------

 +  Changed some wordings in Config::Manager::Report
 +  Fixed syntax error in Config::Manager::SendMail
 +  Improved the overview manual page "Config::Manager"
 +  Added "Normalize()" and "MakeDir()" to Config::Manager::File
 +  Added missing documentation parts to Config::Manager::File
 +  Config::Manager::File now localizes all global Perl variables
 +  Config::Manager::File now uses file locking (flock)
 +  Added new prerequisite "Fcntl" to Makefile.PL
 +  Removed the pointless file histories from all modules


Legal issues:
-------------

This package with all its parts is

Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
All rights reserved.

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for more details!


Prerequisites:
--------------

Perl version 5.000 or higher, modules IO::File, File::Compare,
File::Copy, Net::SMTP and MD5.


Installation:
-------------

Please see the file "INSTALL.txt" in this distribution for instructions
on how to install this package.


Changes over previous versions:
-------------------------------

Please refer to the file "CHANGES.txt" in this distribution for a detailed
version history.


Documentation:
--------------

The documentation of this package is included in POD format (= "Plain Old
Documentation") in the various "*.pm" files in this distribution, the human-
readable markup-language standard for Perl documentation.

By building this package, this documentation will automatically be converted
into a man page, which will automatically be installed in your Perl tree for
further reference in this process, where it can be accessed via the command
(e.g.) "man Config::Manager" (UNIX) or "perldoc Config::Manager" (UNIX and Win32).

If Perl is not currently available on your system, you can also read this
documentation directly.

Moreover, there is a short introduction given in file "Intro.txt", to which
belong the two pictures "Bild1.jpg" and "Bild2.jpg".


What does it do:
----------------

The objective of this module suite is to support configuration management.

Please see the documentation (which is in German only, unfortunately) for
more details (in particular file "Intro.txt").


Author's note:
--------------

If you have any questions, suggestions or need any assistance, please
let me know!

Please do send feedback, this is essential for improving this module
according to your needs!

I hope you will find this module useful. Enjoy!

Yours,
--
  Steffen Beyer <sb@engelschall.com> http://www.engelschall.com/u/sb/
  "There is enough for the need of everyone in this world, but not
   for the greed of everyone." - Mohandas Karamchand "Mahatma" Gandhi