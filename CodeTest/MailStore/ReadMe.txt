Project Name: MailStore
Description : This is an assignment project

Prerequisites:
---------------
1) Perl version used : perl-5.24.0
2) Application developed using Vagrant, you need to have vagrant or any linux environment

Background:
-----------
I went thru below links to understand about maildir as the mail messages are not just text files
http://www.courier-mta.org/maildir.html
http://www.courier-mta.org/maildirmake.html
I used maildirmake command to create files in maildir folders


Structure of project
---------------------
CodeTest/
   |
   |-> Design-Docs: I have attached two documents (pdf and image) both are same design
   |
   |-> MailDir  (input folder for the program - location where mail messages are kept)
          |-> cur
          |-> new : 5 messages are present here
          |-> tmp
   | 
   |-> Storage (output folder - where messages will be written to
          |-> <mail_message_id-1>
          |-> <mail_message_id-2>
          |-> mappings.yaml (a yaml file that stores all the messageids and their respective stored paths)
   |
   |-> MailStore (Main Application)
          |-> _build
               |-> (Build related files)
          |
          |-> bin
               |-> mailstore.pl  (starting point - script to run the application)
          |
          |-> blib 
               |-> (Build related files)
          |
          |-> etc
               |-> logger.conf
               |-> mailstore.conf
          |
          |-> lib
               |-> MailStore.pm
               |-> Mailstore
                      |-> Service.pm
                      |-> MailExtract.pm
                      |-> Report.pm
                      |-> Storage.pm
                      |-> Common
                            |-> Config.pm
                            |-> Logger.pm
                            |-> Instance.pm
          |
          |-> log
                |-> app.log
          |-> t
                |-> runall.t
                |-> scripts
                       |-> (Test files)
                |-> data
                       |-> (input - source directory)
                       |-> (output - target directory)
          |-> Build
          |-> Build.PL
          |-> MANIFEST
          |-> MYMETA.json
          |-> MYMETA.yaml
          |-> ReadMe.txt

Future Enhancements I can think of
-----------------------------------
1) Provide better POD documentation
2) Handling duplicate messages (may be keep duplicates or a flag to indicate duplicate)
3) Signal Handling if the program is abruptly stopper/killed or support for the program to pause/resume
4) To provide realtime progress of the work happening.
5) Support for multiple instances running at the same time
6) Log rotation everyday or for everyrun
7) Better command line report using either Text::Table or Perl6::Form
8) Improve the performance using ForkManager by running multi processes.
9) Creating MD5 hash from messageId instead of using messageId for folder creation
10) Remove messages after copy is completed
11) Archiving the attachments
