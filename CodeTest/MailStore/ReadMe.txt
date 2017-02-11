
Project Name: MyApp

1) Using Perl version : perl-5.24.0
2) Running the project on Vagrant
3) Command line tool to run the project is bin/myapp.pl

I went thru below links to understand about maildir
http://www.courier-mta.org/maildir.html
http://www.courier-mta.org/maildirmake.html

I used maildirmake command to create files in /Input/maildir folders

maildirmake -f drafts maildir
maildirmake -f inbox maildir
maildirmake -f sent maildir
