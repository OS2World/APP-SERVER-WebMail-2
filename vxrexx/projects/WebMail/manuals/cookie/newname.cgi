#!/usr/bin/perl

$logfile=  "/usr/lib/httpd/hosts/lakeweb/htdocs/testlog";
$indexurl= "/usr/lib/httpd/hosts/lakeweb/htdocs/testcookie/";
$newname= "/usr/lib/httpd/hosts/lakeweb/htdocs/testcookie/newname.txt";

#
#----------------------------------------------------------
#

#
#Read the input data
#
# get input from client ( html page ) into $buffer.
read( STDIN, $buffer, $ENV{'CONTENT_LENGTH'} );

# Split the data
@pairs= split( /&/, $buffer );

foreach $pair( @pairs ){

   #Create associated list.
   ( $label, $value )= split( /=/, $pair );

   #parse out the value identities. ( Matt's )
   $value=~ tr/+/ /;
   $value=~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value=~ s/<!--(.|\n)*-->//g;

   #Associate pairs to DATA.
   $DATA{ $label }= $value;

}
#
#----------------------------------------------------------
#

#check for previous cookie, should have cookie if here!


$rootcookie{ 'first' }= $DATA{ 'fname' };
$rootcookie{ 'last' }= $DATA{ 'lname' };
$rootcookie{ 'email' }= $DATA{ 'email' };

$newcookie= &join_cookie( %rootcookie );

$|=1;
print "Content-type: text/html\n";
print "Set-Cookie: id=$newcookie; domain=.lakeweb.com;";
print " expires=", &date( time + 700000, 1 ), "; path=/\n\n";

      print "<head><META HTTP-EQUIV=\"Refresh\"";
      print "CONTENT=\"0; URL=./\" >";
      print "Quick Link</head><body>\n\r";
      print "<a href=\"http://www.lakeweb.com/testcookie/\">\n\r";
      print "return to cookie test</a>";
      print "<p><p>$rootcookie{ 'first' }";
      print "<p>$rootcookie{ 'last' }";
      print "<p>$rootcookie{ 'email' }";
      print "<p>$newcookie";
      print "</body>";

#.end

sub join_cookie
{
   local( %set )= @_;
   local( $newcookie );
   foreach $key( keys %set )
   {
      $newcookie.= "$key\~$rootcookie{ $key }:";
   }
   return $newcookie;
}

sub date
{
   local( $time, $format )= @_;
   #local( $format )= pop( @_ );

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
      return "$weekday[$wday], $mday-$month-$year $hour\:$min\:$sec GMT";
}
