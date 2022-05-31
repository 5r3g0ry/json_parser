#!/bin/perl



use strict;
use warnings;
use Data::Dumper;


my $DEBUG = 0;

my $json = qq(
{
  "request_id":"05cbb8",
  "lease_id":"",
  "renewable":false,
  "lease_duration":0,
  "data":null,
  "wrap_info":null,
  "warnings":null,
  "auth": {
            "client_token":"qYdveuuuN",
            "accessor":"fdsfjasldfkjsalfaksjdfl",
            "lease_duration":1800,
            "token_type":"service",
            "orphan":true
          }
}
);

from_json_string($json);


sub from_json_string {
    my $s = shift;
    $s =~ s{\n}{}g;
    my @tokens = lex($s);
    print join('  ', @tokens)."\n";
    my $r;
    ($r,@tokens) =  parse(@tokens);
    print Dumper $r;
    print "-------------------------------\n\n\n";
}



###############
### PARSER  ###
###############
sub parse {
  print "\n###FUNCTION PARSE\n" if ($DEBUG);
  my @tokens = @_;
  my $t = shift @tokens;
  print "PARSE First token: $t\n" if ($DEBUG);
  print "PARSE Tokens: " if ($DEBUG);
  print join(",",@tokens)."\n" if ($DEBUG);

  if ($t eq '[') {
      my ($json_array, @tokens) = parse_array(@tokens);
      print "ARRAY RETURN Tokens: " if ($DEBUG);
      print join(",",@tokens)."\n" if ($DEBUG);
      return ($json_array, @tokens);
  }
  elsif ($t eq '{') { 
      my ($json_object, @tokens) = parse_object(@tokens);
      print "OBJECT RETURN Tokens: " if ($DEBUG);
      print join(",",@tokens)."\n" if ($DEBUG);
      return ($json_object, @tokens);
  }
  else {
      return $t, @tokens;
  }
}

sub parse_array {
    print "\n###FUNCTION PARSE ARRAY\n" if ($DEBUG);
    my @tokens = @_;
    my (@json_array, $json_value);

    my $t = $tokens[0];
    print "ARRAY First token: $t\n" if ($DEBUG);

    if ($t eq ']') {
        print "Detected end of array ]\n" if ($DEBUG);
        shift @tokens;
        return \@json_array, @tokens;
    }
    
    while (1) {
        print "2 ARRAY tokens: " if ($DEBUG);
        print join(",",@tokens)."\n" if ($DEBUG);

        ($json_value, @tokens) = parse(@tokens);
        print "\nBACK TO ARRAYPARSE\n" if ($DEBUG);
        print "PUSHING TO JSON__ARRAY:  " if ($DEBUG);
        print $json_value if ($DEBUG);
        print "\n" if ($DEBUG);

        push @json_array, $json_value;

        print "JSONARRAY " if ($DEBUG);
        print join(",",@json_array)."\n" if ($DEBUG);

        print "1 ARRAY Tokens: " if ($DEBUG);
        print join(",",@tokens)."\n" if ($DEBUG);

        $t = $tokens[0];
        if ($t eq ']') {
            print "Detected inner end of array ]\n" if ($DEBUG);
            shift @tokens;
            print "INNER  Tokens: " if ($DEBUG);
            print join(",",@tokens)."\n" if ($DEBUG);
            return \@json_array, @tokens;
        }
        elsif ($t ne ',') {
            die('Expected comma after object in array');
        }
        else {
            shift @tokens;
        }
    }
}
 
sub parse_object {
    print "\n###FUNCTION PARSE OBJECT\n" if ($DEBUG);
    my @tokens = @_;
    my (%json_object,$json_key,$json_value);

    print "OBJECT tokens: " if ($DEBUG);
    print join(",",@tokens)."\n" if ($DEBUG);

    my $t = $tokens[0];
    print "OBJECT First token: $t\n" if ($DEBUG);

    if ($t eq '}') { 
        print "Detected end of object }\n" if ($DEBUG);
        shift @tokens;
        return \%json_object, @tokens;
    }

    while (1) {
        $json_key = $tokens[0]; 
        print "JSON_KEY: $json_key\n" if ($DEBUG);

        shift @tokens;
        shift @tokens;

        ($json_value, @tokens) = parse(@tokens);
        print "\nBACK TO OBJECTPARSE\n" if ($DEBUG);
        print "JSON_VALUE_OBJECT: " if ($DEBUG);
        print $json_value if ($DEBUG);
        print "\n" if ($DEBUG);
        print "OBJECT Tokens: " if ($DEBUG);
        print join(",",@tokens)."\n" if ($DEBUG);

        $json_object{$json_key} = $json_value;

        $t = $tokens[0];
        print "The value of t now is: $t\n" if ($DEBUG);
        if ($t eq '}') {
            print "Detected inner end of object }\n" if ($DEBUG);
            print "OBJECT Tokens: " if ($DEBUG);
            print join(",",@tokens)."\n" if ($DEBUG);
            shift @tokens;
            return \%json_object, @tokens;
        }
        elsif ($t ne ',') { 
            die('Expected comma after pair in object');
        }
        $t = shift @tokens;
    }
    die('Expected end-of-object brace');
}




###############
### LEXER   ###
###############
sub lex {
  my $string = shift;
  my @tokens;
  my $value;

  while ($string) {

    print "\nSTRING0: $string\n" if ($DEBUG > 2);

    ($value, $string) = lex_string($string);
    if (defined $value) {
        push @tokens,$value;
        next;
    }
    print "\nSTRING1: $string\n" if ($DEBUG > 2);

    ($value, $string) = lex_number($string);
    if (defined $value) {
        push @tokens,$value;
        next;
    }
    print "\nSTRING2: $string\n" if ($DEBUG > 2);

    ($value, $string) = lex_bool($string);
    if (defined $value) {
        push @tokens,$value;
        next;
    }
    print "\nSTRING3: $string\n" if ($DEBUG > 2);

    ($value, $string) = lex_null($string);
    if (defined $value) {
        push @tokens,$value;
        next;
    }
    print "STRING4: $string\n" if ($DEBUG > 2);

    if ($string =~ m{^\s+}) {
      print "Detected empty space!\n" if ($DEBUG > 2);
      $string =~ s{^\s+}{};
    }

    if ($string =~ m{(^[\{\}\[\],\:])}) {
      print "Detected JSON_SYNTAX! $1\n" if ($DEBUG > 2);
      push @tokens,$1;
      $string =~ s/^[\{\}\[\],\:]//;
    }
    print "STRING5: $string\n" if ($DEBUG > 2);
    print "----------------\n" if ($DEBUG);
  }
  return @tokens;
}

sub lex_string {
  my $v = shift;
  print "\nCalled lex_string with: $v\n" if ($DEBUG) > 2;
  if ($v =~ m/^"([,;\{\}_\.\-\:\*\'\&\w]*)"(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return $1, $2;
  }
  elsif ($v =~ m/^'([,;\{\}_\.\-\:\*\'\&\w]*)'(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return $1, $2;
  }
  else {
      print "no match\n" if ($DEBUG) > 2;
      return undef,$v;
  }
}

sub lex_number {
  my $v = shift;
  print "\nCalled lex_number with: $v\n" if ($DEBUG) > 2;
  if ($v =~ m/^([\.\d]+)(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return $1, $2;
  }
  else {
      return undef,$v;
  }
}

sub lex_bool {
  my $v = shift;
  print "\nCalled lex_bool with: $v\n" if ($DEBUG) > 2;
  if ($v =~ m/^(true)(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return $1, $2;
  }
  elsif ($v =~ m/^(false)(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return $1, $2;
  }
  else {
      return undef,$v;
  }
}

sub lex_null {
  print "\nCalled lex_null\n" if ($DEBUG) > 2;
  my $v = shift;
  if ($v =~ m/^(null)(.*)/) {
      print "matched $1\n" if ($DEBUG) > 2;
      return 'null', $2;
  }
  else {
      return undef,$v;
  }
}
