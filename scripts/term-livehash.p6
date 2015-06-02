#!/usr/bin/env perl6

# Proof-of-concept implementation and demo for a Hash-like data structure,
# which can print its contents to the terminal and automatically update that
# print-out in-place when its contents change.
# 
# Possibly useful for longer-running programs that want to show progress in
# the form of multiple aggregate statistics.

class Term::LiveHash does Associative {
    my ($l-left, $l-up, $l-down, $l-clear);
    
    has %!data handles<EXISTS-KEY BIND-KEY>;
    has %!index;
    has @!index;
    has $!active = False;
    
    submethod BUILD {
        # Retrieve terminal codes the first time an instance is created:
        once ($l-left, $l-up, $l-down, $l-clear)
            = (qqx[tput $_] for <cr cuu1 cud1 el>);
    }
    
    method AT-KEY (\key) {
        Proxy.new(
            FETCH => -> $       { %!data{key} },
            STORE => -> $, \val { $.ASSIGN-KEY(key, val) }
        )
    }
    
    method ASSIGN-KEY ($key, Mu $value) {
        %!data{$key} = $value;
        
        if $!active and %!index{$key} -> $i {
            print $l-left, $l-up x $i, $l-clear,
                  "$key: $value",
                  $l-left, $l-down x $i;
        }
        else {
            $_++ for %!index.values;
            %!index{$key} = 1;
            push @!index, $key;
            say "$key: $value" if $!active;
        }
    }
    
    method DELETE-KEY ($key) {
        $.hide;
        %!data{$key}:delete;
        my $i = %!index{$key}:delete;
        for %!index.values { $_-- if $_ > $i };
        splice @!index, *-$i, 1;
        $.show;
    }
    
    method hide {
        $!active = False;
        print $l-left, $l-up, $l-clear for ^%!data;
    }
    
    method show {
        $!active = True;
        for @!index { say "$_: %!data{$_}" };
    }
}

########## Demo ##########

my %stats := Term::LiveHash.new;
%stats.show;

for ^100 -> $t {
    
    %stats<wheeee> = "." x (16 + 15*sin($t/5));
    
    %stats<apples>++;
    
    %stats<oranges> += 5   if $t <  65 and $t %% 7;
    %stats<oranges>:delete if $t == 65;
    
    %stats<bananas> = 3    if $t == 15;
    %stats<bananas> *= 3   if $t >  15 and $t %% 3;
    
    if $t > 0 and $t %% 25 {
        %stats.hide;
        say "~~~[ $t% done! ]~~~";
        %stats.show;
    }
    
    sleep 0.07;
    
}

say "~~~[ the end ]~~~";
