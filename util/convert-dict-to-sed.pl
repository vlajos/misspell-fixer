#!/usr/bin/perl -w
use strict;

print "#!/bin/sed\n";

sub print_sed_regexp{
    my ($prefix, $from, $suffix, $to) = @_;
    print "s/$prefix$from$suffix/$to/g\n";
}

while(<>){
    if($_ =~/^(.*)\|(.*)$/ ){
        my ($from, $to) = ($1, $2);
        my $prefix = '';
        my $suffix = '';
        if(substr($from, 0, 2) eq '\b'){
            $prefix = '\b';
            $from = substr($from, 2);
        }
        if(substr($from, -2) eq '\b'){
            $suffix = '\b';
            $from = substr($from, 0, -2);
        }
        print_sed_regexp($prefix, lc($from), $suffix, lc($to));
        print_sed_regexp($prefix, uc($from), $suffix, uc($to));
        print_sed_regexp($prefix, ucfirst($from), $suffix, ucfirst($to));
    }else{
        warn("unable to convert: $_\n");
    }
}