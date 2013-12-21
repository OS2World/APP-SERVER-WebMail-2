#!/usr/bin/perl

$logfile=  "/usr/lib/httpd/hosts/lakeweb/htdocs/logs/cookiehit";
$testfile= "/usr/lib/httpd/hosts/lakeweb/htdocs/testfile";
$indexurl= "/usr/lib/httpd/hosts/lakeweb/htdocs/testcookie/cookie_index.html";
$newname= "/usr/lib/httpd/hosts/lakeweb/htdocs/testcookie/newname.txt";

#
#----------------------------------------------------------
#
#This script works on one cookie called 'root' and one called 'id'

#check for previous cookie else, new vistor
if( $hascookie= defined( $ENV{ 'HTTP_COOKIE' } ) )
{
   #This script works on one cookie called 'root'
   %rootcookie= &split_cookie( $ENV{ 'HTTP_COOKIE' }, 'root' );
   %idcookie= &split_cookie( $ENV{ 'HTTP_COOKIE' }, 'id' );
   $rootcookie{ 'count' }++;
   $newcookie= &join_cookie( %rootcookie );
}
else
{
   $newcookie= "count\~1:timeinit\~" . time;
}


         #write the new cookie first
$|=1;
print "Content-type: text/html\n";
print "Set-Cookie: root=$newcookie; domain=.lakeweb.com;";
print " expires=", &date( time + 700000, 1 ), "; path=/\n\n";

open( FILE,"$indexurl" ) || die "can't open $indexurl: $!\n";
@lines= <FILE>;
close( FILE );

foreach( @lines ){
   if( !/<!---cookies---!>/ ){
      print;
   }else
   {
      print "cookie:$tester<br>\n\r";
      print "Current date: ", &date( time ), "<br>\n\r";
      print "Cookie expires: ", &date( time + 100000 ), "<br><br>\n\r";
      print "<center>";
      if( $hascookie )
      {
         print "You have loaded this page $rootcookie{ 'count' } ";
         print "times now.<br>\nYour first visit was ";
         print &date( $rootcookie{ 'timeinit' } ), "<br>";
         print "YOU HAVE A COOKIE";

         if( $idcookie{ 'first' } ne '' ){
            print "  $idcookie{ 'first' }!<br>";
         }else{
            open( FILE,"$newname" ) || die "can't open $newname: $!\n";
            print <FILE>;
            close FILE;
         }
      }
      else
      {
         print "This is your first visit or your browser<br>";
         print "does not suport cookies.  If you get this<br>";
         print "message after reloading, you need Netscape.<br>";
      }
      print "<br><center>All hits counted: ";
      print "<IMG SRC=\"http://www.lakeweb.com/cgi-bin/counter2.xbm\">";
      print "</center><p>\n\r";
   }
}

open( LOG, ">>$logfile" ) || die "can't open $logfile: $\n";
      print LOG &date( time ), "\n";
      print LOG "$idcookie{ 'first' }  $idcookie{ 'last' }  $idcookie{ 'email' }\n";
      print LOG "remote adr: $ENV{'REMOTE_ADDR'}\n";
      print LOG "remote host: $ENV{'REMOTE_HOST'}\n\n";
close( LOG );

#.end program
#
#----------------------------------------------------------
#
#
#subs
#

sub split_cookie
{
   # put cookie into array
   local( $incookie, $tag )= @_;
   local( %cookie );
$tester= $incookie;
   local( @temp )= split( /; /, $incookie );
   foreach ( @temp )
   {
      ( $temp, $temp2 )= split( /=/ );
      $cookie{ $temp }= $temp2;
   }
   return &split_sub_cookie( $cookie{ $tag } );
}

sub split_sub_cookie
{
   local( $cookie )= @_;
   local( %newcookie );
   local( @temp )= split( /:/, $cookie );
   foreach ( @temp )
   {
      ( $temp, $temp2 )= split( /~/ );
      $newcookie{ $temp }= $temp2;
   }
   return %newcookie;
}

sub join_cookie
{
   local( %set )= @_;
   local( $newcookie );
   foreach $key( keys %set )
   {
      $newcookie.= "$key\~$set{ $key }:";
   }
   return $newcookie;
}

sub date
{
   local( $time, $format )= @_;

   local( $sec, $min, $hour, $mday, $mon, $year,
          $wday, $yday, $isdst )= localtime( $time );

   $sec = "0$sec" if ($sec < 10);
   $min = "0$min" if ($min < 10);
   $hour = "0$hour" if ($hour < 10);
   $mon = "0$mon" if ($mon < 10);
   $mday = "0$mday" if ($mday < 10);
   local( $month )= ($mon + 1);
   local( @months )= ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );

   local( @weekday )=( "Monday", "Tuesday", "Wednesday",
              "Thursday", "Friday", "Saturday", "Sunday" );

   if ( !defined( $format ) ){
      return "$mday $months[$mon] 19$year at $hour\:$min\:$sec";
   }
   #else
      return "$weekday[$wday], $month-$mday-$year $hour\:$min\:$sec GMT";
}
